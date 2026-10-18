import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import part_fun, part_study, part_hyg_cq, part_edge, part_integ_buffer

VOCAB = ("code architecture cleanup tests systems combat animation cinematics story dialogue quests openworld npc "
         "economy items ui ux audio music vfx assets art tools performance accessibility localization save time "
         "difficulty fun release marketing legal team docs ai level business").split()

cat = {
    "fun_lenses": part_fun.build(),
    "study": part_study.build(),
    "hygiene": part_hyg_cq.hygiene(),
    "code_quality": part_hyg_cq.code_quality(),
    "edge_cases": part_edge.build(),
    "integration_days": part_integ_buffer.integration_days(),
    "monthly_review": part_fun.MONTHLY_REVIEW,
    "quarterly_replan": part_fun.QUARTERLY_REPLAN,
    "gate_review": part_fun.GATE_REVIEW,
    "buffer_tasks": part_integ_buffer.buffer_tasks(),
    "start_of_day": part_fun.START_OF_DAY,
    "end_of_day": part_fun.END_OF_DAY,
}

errs = []
def need(name, n, minimum):
    if n < minimum:
        errs.append(f"{name}: {n} < {minimum}")

def dups(name, keys):
    seen = set()
    for k in keys:
        if k in seen:
            errs.append(f"duplicate in {name}: {k}")
        seen.add(k)

need("fun_lenses", len(cat["fun_lenses"]), 180); dups("fun_lenses", [x["lens"] for x in cat["fun_lenses"]])
need("study", len(cat["study"]), 400); dups("study", [x["topic"] for x in cat["study"]]); dups("study.exercise", [x["exercise"] for x in cat["study"]])
need("hygiene", len(cat["hygiene"]), 220); dups("hygiene", [x["chore"] for x in cat["hygiene"]])
need("code_quality", len(cat["code_quality"]), 220); dups("code_quality", [x["item"] for x in cat["code_quality"]])
need("integration_days", len(cat["integration_days"]), 60); dups("integration_days", [x["focus"] for x in cat["integration_days"]])
need("buffer_tasks", len(cat["buffer_tasks"]), 120); dups("buffer_tasks", [x["title"] for x in cat["buffer_tasks"]])
for k in ("start_of_day", "end_of_day"):
    if not 6 <= len(cat[k]) <= 10:
        errs.append(f"{k} count {len(cat[k])}")
missing = [t for t in VOCAB if t not in cat["edge_cases"]]
extra = [t for t in cat["edge_cases"] if t not in VOCAB]
if missing: errs.append(f"edge tags missing {missing}")
if extra: errs.append(f"edge tags not in vocab {extra}")
all_edges = []
for t, lst in cat["edge_cases"].items():
    need(f"edge_cases[{t}]", len(lst), 30)
    dups(f"edge_cases[{t}]", lst)
    all_edges += lst
for x in cat["fun_lenses"] + cat["buffer_tasks"]:
    for t in x["tags"]:
        if t not in VOCAB: errs.append(f"bad tag {t}")
for x in cat["buffer_tasks"]:
    if "{area}" not in x["title"] or not all("{area}" in s for s in x["steps"][:1]):
        errs.append(f"no area placeholder: {x['title']}")
domains = sorted(set(x["domain"] for x in cat["study"]))

out = sys.argv[1]
with open(out, "w", encoding="utf-8") as f:
    json.dump(cat, f, ensure_ascii=False, indent=1)

print("domains", len(domains), domains)
for k, v in cat.items():
    print(k, len(v) if isinstance(v, (list, dict)) else "")
print("edge total", len(all_edges), "min per tag", min(len(v) for v in cat["edge_cases"].values()))
print("cross-tag duplicate edges", len(all_edges) - len(set(all_edges)))
print("ERRORS:" if errs else "OK", *errs, sep="\n")
