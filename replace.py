import re
with open('lib/features/news/widgets/post_comments_modal.dart', 'r', encoding='utf-8') as f:
    c = f.read()

replies_rx = r"Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*Text\(data\['authorName'\] \?\? 'Unknown', style: const TextStyle\(fontWeight: FontWeight\.bold, fontSize: 12\), overflow: TextOverflow\.ellipsis\),\s*\),\s*const SizedBox\(width: 6\),\s*if\s*\(data\['role'\] != null\)\s*Flexible\(\s*child:\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 4, vertical: 1\),\s*decoration: BoxDecoration\(\s*color: Colors\.blue\.withOpacity\(0\.1\),\s*borderRadius: BorderRadius\.circular\(4\),\s*\),\s*child:\s*Text\(\s*data\['role'\],\s*style: const TextStyle\(fontSize: 9, color: Colors\.blue, fontWeight: FontWeight\.bold\),\s*overflow: TextOverflow\.ellipsis,\s*\),\s*\),\s*\),\s*\],\s*\)"
replies_rep = """Text(data['authorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  if (data['studentContext'] != null || data['role'] != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (data['studentContext'] != null) ...[
                                          Flexible(
                                            child: Text(data['studentContext'], style: TextStyle(fontSize: 10, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (data['role'] != null)
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                data['role'],
                                                style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ]"""

c = re.sub(replies_rx, replies_rep, c)

main_rx = r"Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*Text\(\s*data\['authorName'\] \?\? 'Unknown',\s*style: const TextStyle\(fontWeight: FontWeight\.bold, fontSize: 13\),\s*overflow: TextOverflow\.ellipsis\s*\),\s*\),\s*const SizedBox\(width: 6\),\s*if\s*\(data\['role'\] != null\)\s*Flexible\(\s*child:\s*Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 6, vertical: 2\),\s*decoration: BoxDecoration\(\s*color: Colors\.blue\.withOpacity\(0\.1\),\s*borderRadius: BorderRadius\.circular\(4\),\s*\),\s*child:\s*Text\(\s*data\['role'\],\s*style: const TextStyle\(fontSize: 10, color: Colors\.blue, fontWeight: FontWeight\.bold\),\s*overflow: TextOverflow\.ellipsis,\s*\),\s*\),\s*\),\s*\],\s*\)"
main_rep = """Text(
                                        data['authorName'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      if (data['studentContext'] != null || data['role'] != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (data['studentContext'] != null) ...[
                                              Flexible(
                                                child: Text(data['studentContext'], style: TextStyle(fontSize: 11, color: Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            if (data['role'] != null)
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    data['role'],
                                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ]"""
c = re.sub(main_rx, main_rep, c)

with open('lib/features/news/widgets/post_comments_modal.dart', 'w', encoding='utf-8') as f:
    f.write(c)

print('Replaced')
