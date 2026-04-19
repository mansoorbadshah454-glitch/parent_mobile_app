const fs = require('fs');
const path = 'lib/features/news/widgets/post_comments_modal.dart';
let content = fs.readFileSync(path, 'utf8');

// For Replies
const repliesRegex = /Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*Text\(data\['authorName'\]\s*\?\?\s*'Unknown',\s*style:\s*const\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*fontSize:\s*12\),\s*overflow:\s*TextOverflow\.ellipsis\),\s*\),\s*const\s*SizedBox\(width:\s*6\),\s*if\s*\(data\['role'\]\s*!=\s*null\)\s*Flexible\(\s*child:\s*Container\(\s*padding:\s*const\s*EdgeInsets\.symmetric\(horizontal:\s*4,\s*vertical:\s*1\),\s*decoration:\s*BoxDecoration\(\s*color:\s*Colors\.blue\.withOpacity\(0\.1\),\s*borderRadius:\s*BorderRadius\.circular\(4\),\s*\),\s*child:\s*Text\(\s*data\['role'\],\s*style:\s*const\s*TextStyle\(fontSize:\s*9,\s*color:\s*Colors\.blue,\s*fontWeight:\s*FontWeight\.bold\),\s*overflow:\s*TextOverflow\.ellipsis,\s*\),\s*\),\s*\),\s*\],\s*\)/g;

const repliesReplacement = `Text(data['authorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  if (data['studentContext'] != null || (data['role'] != null && (data['authorName'] ?? '').toString().contains("'s Parent"))) ...[
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
                                  ]`;

if (content.match(repliesRegex)) {
    content = content.replace(repliesRegex, repliesReplacement);
    console.log("Replaced replies row");
} else {
    console.log("Could not find replies row");
}

// For Main comments
const mainRegex = /Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*Text\(\s*data\['authorName'\]\s*\?\?\s*'Unknown',\s*style:\s*const\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*fontSize:\s*13\),\s*overflow:\s*TextOverflow\.ellipsis\s*\),\s*\),\s*const\s*SizedBox\(width:\s*6\),\s*if\s*\(data\['role'\]\s*!=\s*null\)\s*Flexible\(\s*child:\s*Container\(\s*padding:\s*const\s*EdgeInsets\.symmetric\(horizontal:\s*6,\s*vertical:\s*2\),\s*decoration:\s*BoxDecoration\(\s*color:\s*Colors\.blue\.withOpacity\(0\.1\),\s*borderRadius:\s*BorderRadius\.circular\(4\),\s*\),\s*child:\s*Text\(\s*data\['role'\],\s*style:\s*const\s*TextStyle\(fontSize:\s*10,\s*color:\s*Colors\.blue,\s*fontWeight:\s*FontWeight\.bold\),\s*overflow:\s*TextOverflow\.ellipsis,\s*\),\s*\),\s*\),\s*\],\s*\)/g;

const mainReplacement = `Text(
                                        data['authorName'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      if (data['studentContext'] != null || (data['role'] != null && (data['authorName'] ?? '').toString().contains("'s Parent"))) ...[
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
                                      ]`;

if (content.match(mainRegex)) {
    content = content.replace(mainRegex, mainReplacement);
    console.log("Replaced main row");
} else {
    console.log("Could not find main row");
}

fs.writeFileSync(path, content, 'utf8');
console.log('Done');
