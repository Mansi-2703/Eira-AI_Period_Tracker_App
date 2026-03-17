class DisorderInfo {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String imagePath;

  DisorderInfo({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.imagePath,
  });
}

final List<DisorderInfo> disordersData = [
  DisorderInfo(
    id: 'pms',
    title: 'PMS',
    shortDescription: 'Premenstrual Syndrome - Mood and physical changes before your period',
    fullDescription: '''PMS (Premenstrual Syndrome)

A few days before your period, your body may feel a little different. This is called PMS. You might feel bloated, tired, emotional, or even a bit irritated for no clear reason. It's completely normal. Your hormones are simply shifting like waves in the ocean.

Some girls feel mild changes, while others feel it more strongly. You might crave sweets, feel like crying, or want to be alone. Your body is preparing for your period, and these feelings are part of that process.

To feel better, try simple things: drink water, get enough sleep, and move your body gently like walking or stretching. Talking to someone you trust can also help.

Remember, PMS is not "being dramatic." It's your body speaking in its own language. Learning to listen to it makes everything easier.''',
    imagePath: 'assets/images/pms.png',
  ),
  DisorderInfo(
    id: 'pmdd',
    title: 'PMDD',
    shortDescription: 'Premenstrual Dysphoric Disorder - More intense emotional changes',
    fullDescription: '''PMDD (Premenstrual Dysphoric Disorder)

PMDD is like a stronger version of PMS. It affects emotions more deeply. You may feel very sad, anxious, angry, or overwhelmed before your period starts.

The key difference is intensity. These feelings can interfere with daily life, school, or relationships. It's not just "mood swings," it's something your body needs support with.

If you notice extreme emotions every month at the same time, it's important to talk to a doctor or a trusted adult. There is help available, and you don't have to deal with it alone.

Taking care of yourself becomes even more important. Healthy food, sleep, and calming activities like journaling or listening to music can help.

Most importantly, be kind to yourself. Your feelings are real, and asking for help is a strong and brave step.''',
    imagePath: 'assets/images/pmdd.png',
  ),
  DisorderInfo(
    id: 'pcos',
    title: 'PCOS',
    shortDescription: 'Polycystic Ovary Syndrome - Hormonal imbalance affecting cycles',
    fullDescription: '''PCOS (Polycystic Ovary Syndrome)

PCOS is a condition where your hormones are slightly out of balance. This can affect your periods, skin, and even hair growth.

Some girls with PCOS may have irregular periods, acne, or weight changes. It doesn't mean something is "wrong" with you, it just means your body works a little differently.

PCOS is common and manageable. Doctors can guide you with lifestyle changes or treatment if needed. Eating balanced meals, staying active, and managing stress can make a big difference.

It's also important to understand that PCOS is not your fault. It's simply how your body is wired.

With the right care and awareness, girls with PCOS can live completely healthy and happy lives.''',
    imagePath: 'assets/images/pcos.png',
  ),
  DisorderInfo(
    id: 'dysmenorrhea',
    title: 'Dysmenorrhea',
    shortDescription: 'Painful Periods - Strong cramps during menstruation',
    fullDescription: '''Dysmenorrhea (Painful Periods)

If your periods come with strong cramps, it's called dysmenorrhea. These cramps happen because your uterus is working to shed its lining.

The pain can feel like tight squeezing in your lower belly or back. For some girls, it's mild. For others, it can be stronger and uncomfortable.

Simple remedies can help: using a hot water bag, resting, gentle stretching, or drinking warm fluids. Sometimes doctors may suggest medicine if the pain is severe.

Pain during periods is common, but it should not stop you from living your daily life. If the pain feels too intense, it's always okay to seek help.

Your body is doing an important job, and taking care of it during this time matters.''',
    imagePath: 'assets/images/dysmenorrhea.png',
  ),
  DisorderInfo(
    id: 'menorrhagia',
    title: 'Menorrhagia',
    shortDescription: 'Heavy Periods - Excessive bleeding during menstruation',
    fullDescription: '''Menorrhagia (Heavy Periods)

Menorrhagia means having very heavy periods. You may need to change pads or tampons very often, or your period may last longer than usual.

It can feel tiring and sometimes overwhelming. You might also feel weak or low on energy because of blood loss.

If your periods feel unusually heavy, it's important to talk to a doctor. There are ways to manage it and make you feel better.

Eating iron-rich foods like spinach, dates, and nuts can help maintain your energy. Rest is equally important.

Remember, your period should not feel like a burden every month. If something feels off, listening to your body is the first step.''',
    imagePath: 'assets/images/menorrhagia.png',
  ),
  DisorderInfo(
    id: 'endometriosis',
    title: 'Endometriosis',
    shortDescription: 'Tissue growth outside uterus causing period pain',
    fullDescription: '''Endometriosis

Endometriosis happens when tissue similar to the lining of the uterus grows outside it. This can cause pain, especially during periods.

The pain might feel deeper and stronger than usual cramps. Some girls also feel discomfort during other times of the month.

It can take time to diagnose, so speaking up about your pain is important. You know your body best.

Doctors can help manage symptoms through treatment. Warm compresses, rest, and gentle care can also provide relief.

Living with endometriosis can be challenging, but support and awareness make a big difference. You are not alone in this journey.''',
    imagePath: 'assets/images/endometriosis.png',
  ),
  DisorderInfo(
    id: 'anemia',
    title: 'Anemia',
    shortDescription: 'Low iron levels causing tiredness and weakness',
    fullDescription: '''Anemia

Anemia happens when your body doesn't have enough healthy red blood cells. This can make you feel tired, weak, or dizzy.

It is common in girls, especially if periods are heavy. Your body needs iron to stay strong.

Eating foods like leafy greens, fruits, nuts, and jaggery can help improve iron levels. Sometimes, doctors may suggest supplements.

If you feel tired all the time or notice pale skin, it's a good idea to get checked.

Taking care of your nutrition is like giving your body fuel. A well-nourished body feels stronger and more energetic.''',
    imagePath: 'assets/images/anemia.png',
  ),
  DisorderInfo(
    id: 'menopause',
    title: 'Menopause',
    shortDescription: 'Natural life stage when periods stop completely',
    fullDescription: '''Menopause

Menopause usually happens later in life when periods stop completely. But learning about it early helps you understand the full journey of your body.

It marks the end of menstrual cycles and is a natural phase, not an illness.

Women may experience changes like hot flashes, mood shifts, or sleep issues during this time.

Though it may feel unfamiliar, it's simply another stage of life, like puberty was once new to you.

Understanding menopause helps build awareness and empathy for others too. It reminds us how beautifully the body changes over time.''',
    imagePath: 'assets/images/menopause.png',
  ),
];
