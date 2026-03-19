import json
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

from langchain.vectorstores import FAISS
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import HuggingFacePipeline
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
from langchain.docstore.document import Document

from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
from huggingface_hub import login

with open("medical_guidelines.json", "r", encoding="utf-8") as f:
    med_data = json.load(f)

with open("sportsantecvl.json", "r", encoding="utf-8") as f:
    sport_data = json.load(f)

sport_data = [entry for entry in sport_data if "cancer" in entry.get("Pathologies / Prévention", "").lower()]

l
med_docs = [Document(page_content=d["content"], metadata=d["metadata"]) for d in med_data]
sport_docs = [
    Document(
        page_content=f"{entry['Name']} - {entry['Description']}",
        metadata={"discipline": entry["Discipline"], "url": entry["url"], "address": entry["address"]}
    )
    for entry in sport_data
]

all_docs = med_docs + sport_docs

embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

patient_profile_text = (
    "Breast cancer patient undergoing active treatment, physically active, no major comorbidities."
)

patient_embedding = embeddings.embed_query(patient_profile_text)

candidate_texts = [doc.page_content for doc in all_docs]
candidate_embeddings = embeddings.embed_documents(candidate_texts)

ref_texts = [doc.page_content for doc in med_docs]
ref_embeddings = embeddings.embed_documents(ref_texts)

epsilon1 = 0.6
epsilon2 = 0.4

utility_scores = []
for idx, cand_emb in enumerate(candidate_embeddings):

    f1 = cosine_similarity([patient_embedding], [cand_emb])[0][0]

    sims = cosine_similarity([cand_emb], ref_embeddings)[0]
    f2 = np.max(sims)

    score = epsilon1 * f1 + epsilon2 * f2
    utility_scores.append((score, all_docs[idx]))

utility_scores.sort(key=lambda x: x[0], reverse=True)

top_k = 4
top_candidates = utility_scores[:top_k]

context_text = "\n\n".join([doc.page_content for _, doc in top_candidates])

login(token="your_token_here")

model_id = "mistralai/Mistral-7B-Instruct-v0.1"
tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    device_map="auto",
    torch_dtype="auto"
)

llm_pipeline = pipeline(
    "text-generation",
    model=model,
    tokenizer=tokenizer,
    max_new_tokens=256,
    temperature=0.7,
    do_sample=True
)
llm = HuggingFacePipeline(pipeline=llm_pipeline)

template = """Given this context, suggest
an adapted physical activity plan tailored to this patient’s
needs.. Based on the following documents, provide a detailed recommendation:

{context}

Question: {question}
Answer:"""

prompt = PromptTemplate(template=template, input_variables=["context", "question"])

question = "What physical activity should I recommend to a breast cancer patient during active treatment?"

inputs = {"context": context_text, "question": question}

answer = llm.invoke(prompt.format(**inputs))

print("\nAnswer:\n", answer)

print("\nTop candidate sources and their utility scores:")
for score, doc in top_candidates:
    print(f"- Score: {score:.4f} | Metadata: {doc.metadata}")
