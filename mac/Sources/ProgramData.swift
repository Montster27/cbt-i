import Foundation

struct WeekContent: Identifiable {
    let id: Int
    let title: String
    let theme: String
    let bedtime: String
    let rules: [String]
    let expect: String
    let cognitive: String?
}

let WEEKS: [WeekContent] = [
    WeekContent(
        id: 1,
        title: "Sleep restriction + stimulus control",
        theme: "Build sleep pressure",
        bedtime: "11:45 PM",
        rules: [
            "Get into bed at 11:45 PM only — not before, even if exhausted.",
            "Get out of bed at 5:45 AM every single day, including weekends. Non-negotiable.",
            "If you're awake in bed more than 20 minutes, get up and go to another room until sleepy.",
            "Bed is for sleep only — no phone, no TV, no reading, no lying awake worrying.",
            "No naps. Daytime sleepiness is building the sleep pressure you need.",
            "Fill in your morning log within 30 minutes of waking — estimates are fine.",
        ],
        expect: "This week is the hardest. You'll feel sleep-deprived — that's intentional. The goal is consolidating your fragmented sleep into a solid block before expanding the window.",
        cognitive: nil
    ),
    WeekContent(
        id: 2,
        title: "Add relaxation for racing thoughts",
        theme: "Calm the nervous system",
        bedtime: "11:45 PM (or 11:15 if SE ≥85% for 5 nights)",
        rules: [
            "Continue all Week 1 rules — they remain in effect for the whole program.",
            "Start a 10-minute wind-down routine at 11:30 PM (dim lights, no screens, quiet).",
            "Practice 4-7-8 breathing before lights out (Tools tab).",
            "During night wakings, use the body scan instead of checking the clock (Tools tab).",
            "If SE ≥85% for 5 consecutive nights, move bedtime 15 minutes earlier.",
        ],
        expect: "Sleep should start consolidating. Night wakings may feel shorter even before they fully resolve. The breathing and body scan work on the nervous system activation that drives racing thoughts.",
        cognitive: "Start noticing your thoughts at night — don't fight them yet, just observe. Write them down in the morning. We'll work with them next week."
    ),
    WeekContent(
        id: 3,
        title: "Cognitive restructuring",
        theme: "Challenge the beliefs",
        bedtime: "Adjust per SE — see Progress tab",
        rules: [
            "Continue all core sleep restriction and stimulus control rules.",
            "Each morning, identify one thought you had during the night and write it down.",
            "Look at the Sleep beliefs tool and find which one matches your thought.",
            "Practice the worry postponement technique before bed (Tools tab).",
            "Check your SE and adjust bedtime if warranted.",
        ],
        expect: "Racing thoughts often reduce significantly once you stop arguing with them and start examining the beliefs underneath. This is where the real cognitive shift begins.",
        cognitive: "Key belief to examine this week: 'I need 8 hours to function.' Most adults function adequately on 6–7 hours. The anxiety about the number causes more impairment than the lost sleep itself."
    ),
    WeekContent(
        id: 4,
        title: "Defusion from anxious thoughts",
        theme: "Stop fighting the thoughts",
        bedtime: "Adjust per SE",
        rules: [
            "Continue all core rules.",
            "Practice thought defusion — see the Defusion tool. Thoughts are events, not facts.",
            "Use the 'leaves on a stream' visualization during any night waking.",
            "Stop checking the clock at night. Cover it if needed. Stop the sleep-time math.",
            "Notice and reduce other safety behaviors (calculating hours left, reassurance-seeking).",
        ],
        expect: "By now most people are seeing SE above 80% and the window has likely expanded to 6.5–7 hours. The quality shift — deeper, more restorative sleep — often becomes noticeable this week.",
        cognitive: "Safety behaviors — clock-checking, calculating 'how much sleep I'll get' — are the engine of sleep anxiety. Each check is a small experiment that confirms sleep is dangerous. Stop the experiment."
    ),
    WeekContent(
        id: 5,
        title: "Consolidation + window expansion",
        theme: "Earn back your sleep time",
        bedtime: "Target: 10:30–11:00 PM range",
        rules: [
            "For every 5-night stretch with SE ≥85%, move bedtime 15–30 minutes earlier.",
            "Keep wake time fixed at 5:45 AM — only ever adjust bedtime.",
            "Maintain stimulus control even as things improve — the association is still being built.",
            "Begin thinking about your maintenance habits for after the program ends.",
        ],
        expect: "Sleep should feel qualitatively different — deeper and more restorative even if the total hours are similar to before. Most people are at 6.5–7 hours of solid sleep by week 5.",
        cognitive: nil
    ),
    WeekContent(
        id: 6,
        title: "Maintenance planning",
        theme: "Make this permanent",
        bedtime: "Your settled natural window",
        rules: [
            "Identify your personal warning signs: two bad nights in a row, anxiety creeping in, compensating with early bedtime.",
            "Have a re-engagement plan: if SE drops below 80% for a week, do a 1-week sleep restriction reset.",
            "Keep a weekly (not daily) sleep log as ongoing monitoring.",
            "The stimulus control association — bed = sleep only — must be maintained long-term.",
            "Sleep is now a skill you've built. It responds to the same principles forever.",
        ],
        expect: "You now have the full toolkit. The program ends but the approach is permanent. One bad stretch doesn't erase the gains — just re-apply the tools.",
        cognitive: "Relapse is not failure — it's information. Something changed (stress, illness, travel, schedule shift). Identify it, re-apply sleep restriction for a week, and the gains come back."
    ),
]

struct StepTool: Identifiable, Hashable {
    let id: String
    let title: String
    let when: String
    let desc: String
    let steps: [String]
}

struct Belief: Identifiable, Hashable {
    let id = UUID()
    let belief: String
    let reframe: String
}

struct BeliefsTool {
    let title: String
    let when: String
    let desc: String
    let items: [Belief]
}

let STEP_TOOLS: [StepTool] = [
    StepTool(
        id: "breathing",
        title: "4-7-8 breathing",
        when: "Before lights out · During night wakings",
        desc: "Activates the parasympathetic nervous system within 2–3 cycles. Works by extending the exhale, which directly triggers the vagal brake on arousal.",
        steps: [
            "Exhale completely and slowly through your mouth.",
            "Close your mouth and inhale through your nose for 4 counts.",
            "Hold your breath for 7 counts.",
            "Exhale through your mouth slowly for 8 counts.",
            "Repeat 4 full cycles. Don't force it — let it be gentle.",
        ]
    ),
    StepTool(
        id: "bodyscan",
        title: "Body scan (5 min)",
        when: "During night wakings · When mind is racing",
        desc: "Shifts attention from anxious thought-loops into physical sensation. Doesn't require relaxation — just observation. More effective than trying to 'think yourself calm.'",
        steps: [
            "Lie still, eyes closed, arms at sides.",
            "Bring attention to the top of your head. Just notice — any warmth, pressure, tingling, or nothing.",
            "Slowly move attention down: forehead → jaw → neck → shoulders → chest.",
            "Continue: arms → hands → stomach → lower back → hips → thighs → calves → feet.",
            "No judgment, no trying to relax. Just observe each area for a few seconds.",
            "When the mind wanders (it will), gently return to wherever you were in the body.",
        ]
    ),
    StepTool(
        id: "worrypost",
        title: "Worry postponement",
        when: "11:30 PM pre-bed routine",
        desc: "Racing thoughts at night are often about real problems. This technique doesn't suppress them — it parks them with a plan, removing their urgency from the sleep window.",
        steps: [
            "At 11:30 PM, spend 10 minutes writing down everything on your mind.",
            "For each item, write one sentence: what (if anything) you can do about it tomorrow.",
            "Close the notebook physically. The problems are parked until morning.",
            "When thoughts intrude in bed, remind yourself: 'Written down. Dealt with at 7 AM.'",
            "If a new worry comes, let it — it's just a thought, not an emergency requiring night action.",
            "Over time, the brain learns that night is not problem-solving time.",
        ]
    ),
    StepTool(
        id: "defusion",
        title: "Leaves on a stream (defusion)",
        when: "Night wakings · Any thought-loop moment",
        desc: "An ACT technique. Creates psychological distance from thoughts without suppressing them. Fighting thoughts gives them energy; watching them float by removes it.",
        steps: [
            "Imagine sitting on the bank of a slow, quiet stream.",
            "Each thought that arises — place it on a leaf floating by.",
            "Watch the leaf carry the thought downstream. Don't grab it. Don't push it away.",
            "Example: 'I'll be useless tomorrow' → place it on a leaf → watch it float.",
            "If you find yourself absorbed by a thought (hooked), simply notice: 'I got hooked.' Return to the stream.",
            "The goal is not to stop thoughts. It's to stop engaging with them as if they're facts.",
        ]
    ),
]

let BELIEFS_TOOL = BeliefsTool(
    title: "Sleep beliefs to examine",
    when: "Morning reflection · Week 3 onwards",
    desc: "CBT-I targets the beliefs that maintain insomnia. These aren't irrational — they feel completely true. That's what makes them worth examining.",
    items: [
        Belief(
            belief: "I need 8 hours to function",
            reframe: "Sleep need is individual and usually 6–7 hours for most adults. The anxiety about hitting 8 hours creates hyperarousal that prevents sleep — the belief is self-fulfilling."
        ),
        Belief(
            belief: "One bad night will ruin tomorrow",
            reframe: "Sleep deprivation studies consistently show performance drops are smaller than people predict. Adrenaline, motivation, and context compensate substantially. You've managed before."
        ),
        Belief(
            belief: "I can't cope without sleep",
            reframe: "You are coping — you're doing it right now. The belief amplifies distress and arousal, making sleep harder. This is the exact cycle CBT-I breaks."
        ),
        Belief(
            belief: "Lying in bed resting is almost as good as sleep",
            reframe: "It's not equivalent — and this is precisely why getting up when awake matters. Passive wakefulness in bed trains the brain that bed = wakefulness."
        ),
        Belief(
            belief: "I should be able to control my sleep",
            reframe: "Sleep is involuntary. The harder you try to force it, the more you prevent it. Your role is to set up conditions — sleep is an automatic process that takes over from there."
        ),
    ]
)
