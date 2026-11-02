import '../models/quiz_bank_model.dart';

class QuizBankData {
  static const List<String> categories = [
    'All',
    'Programming',
    'Computer Science',
    'AI & ML',
    'Web Development',
    'Aptitude',
    'General Knowledge',
  ];

  static const List<QuizTopicMeta> topics = [
    // Programming
    QuizTopicMeta(
      topic: 'Java',
      category: 'Programming',
      description: 'Core Java, OOPs, Collections, Exception Handling, JVM',
      iconKey: 'coffee',
    ),
    QuizTopicMeta(
      topic: 'Python',
      category: 'Programming',
      description: 'Syntax, Data structures, Functions, Generators, OOP in Python',
      iconKey: 'terminal',
    ),
    QuizTopicMeta(
      topic: 'C++',
      category: 'Programming',
      description: 'Pointers, Memory management, Templates, STL, OOPs',
      iconKey: 'code',
    ),
    QuizTopicMeta(
      topic: 'JavaScript',
      category: 'Programming',
      description: 'ES6+, Closures, Promises, Event Loop, Async/Await',
      iconKey: 'javascript',
    ),

    // Computer Science
    QuizTopicMeta(
      topic: 'DSA',
      category: 'Computer Science',
      description: 'Arrays, Trees, Graphs, Sorting, Dynamic Programming',
      iconKey: 'account_tree',
    ),
    QuizTopicMeta(
      topic: 'DBMS',
      category: 'Computer Science',
      description: 'SQL queries, Normalization, Transactions, ACID, Indexing',
      iconKey: 'storage',
    ),
    QuizTopicMeta(
      topic: 'Operating Systems',
      category: 'Computer Science',
      description: 'Process scheduling, Threads, Deadlocks, Memory paging',
      iconKey: 'memory',
    ),
    QuizTopicMeta(
      topic: 'Computer Networks',
      category: 'Computer Science',
      description: 'OSI Model, TCP/IP, Routing protocols, DNS, HTTP/HTTPS',
      iconKey: 'hub',
    ),

    // AI & ML
    QuizTopicMeta(
      topic: 'Artificial Intelligence',
      category: 'AI & ML',
      description: 'Search algorithms, Knowledge representation, Heuristics, Agents',
      iconKey: 'psychology',
    ),
    QuizTopicMeta(
      topic: 'Machine Learning',
      category: 'AI & ML',
      description: 'Supervised, Unsupervised, Regression, Classification, Overfitting',
      iconKey: 'auto_graph',
    ),
    QuizTopicMeta(
      topic: 'Deep Learning',
      category: 'AI & ML',
      description: 'Neural networks, Backpropagation, CNN, RNN, Transformers',
      iconKey: 'bubble_chart',
    ),
    QuizTopicMeta(
      topic: 'NLP',
      category: 'AI & ML',
      description: 'Tokenization, Embeddings, Sentiment analysis, Language models',
      iconKey: 'forum',
    ),

    // Web Development
    QuizTopicMeta(
      topic: 'HTML',
      category: 'Web Development',
      description: 'Semantic tags, Forms, SEO structure, Audio/Video, Canvas',
      iconKey: 'html',
    ),
    QuizTopicMeta(
      topic: 'CSS',
      category: 'Web Development',
      description: 'Flexbox, CSS Grid, Responsive design, Box model, Animations',
      iconKey: 'css',
    ),
    QuizTopicMeta(
      topic: 'React',
      category: 'Web Development',
      description: 'Components, Hooks, State management, Virtual DOM, JSX',
      iconKey: 'widgets',
    ),

    // Aptitude
    QuizTopicMeta(
      topic: 'Quantitative Aptitude',
      category: 'Aptitude',
      description: 'Percentages, Ratios, Speed & Time, Work, Probability',
      iconKey: 'calculate',
    ),
    QuizTopicMeta(
      topic: 'Logical Reasoning',
      category: 'Aptitude',
      description: 'Syllogisms, Blood relations, Number series, Coding-decoding',
      iconKey: 'lightbulb',
    ),

    // General Knowledge
    QuizTopicMeta(
      topic: 'General Knowledge',
      category: 'General Knowledge',
      description: 'Science discoveries, World geography, Tech history, Inventions',
      iconKey: 'public',
    ),
  ];

  static List<QuizBankQuestion> get initialQuestions => [
    // ==================== JAVA ====================
    QuizBankQuestion(
      id: 'qb_java_001',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'Which of the following is not a Java primitive data type?',
      options: ['int', 'boolean', 'String', 'char'],
      correctOptionIndex: 2,
      explanation: 'In Java, "String" is a class/object reference type, whereas int, boolean, and char are primitive types.',
    ),
    QuizBankQuestion(
      id: 'qb_java_002',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'Which keyword is used to inherit a class in Java?',
      options: ['implements', 'extends', 'inherits', 'instanceof'],
      correctOptionIndex: 1,
      explanation: 'The "extends" keyword is used to inherit a class, whereas "implements" is used for interfaces.',
    ),
    QuizBankQuestion(
      id: 'qb_java_003',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'What is the default initial capacity of an ArrayList in Java?',
      options: ['5', '10', '16', '32'],
      correctOptionIndex: 1,
      explanation: 'In Java standard library, a newly instantiated ArrayList defaults to an initial capacity of 10 elements when lazily populated.',
    ),
    QuizBankQuestion(
      id: 'qb_java_004',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'Which memory area in the JVM stores local variables and method call frames?',
      options: ['Heap memory', 'Method area', 'Stack memory', 'PermGen'],
      correctOptionIndex: 2,
      explanation: 'Stack memory in the JVM stores method execution frames and primitive local variables. Object instances reside in Heap memory.',
    ),
    QuizBankQuestion(
      id: 'qb_java_005',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'What happens when you synchronize a static method in Java?',
      options: [
        'It locks the "this" instance of the object.',
        'It locks the Class object associated with the class.',
        'It creates a new thread-safe thread pool.',
        'It causes a compilation error in modern Java.'
      ],
      correctOptionIndex: 1,
      explanation: 'Synchronizing a static method locks the Class object (e.g. MyClass.class), ensuring mutual exclusion across all instances of that class.',
    ),
    QuizBankQuestion(
      id: 'qb_java_006',
      topic: 'Java',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'In Java memory model, what guarantee does the "volatile" keyword provide?',
      options: [
        'Atomicity of compound operations',
        'Visibility of changes across threads and instruction reordering prevention',
        'Automatic serialization of the variable',
        'Thread sleeping without CPU spinlock'
      ],
      correctOptionIndex: 1,
      explanation: 'The "volatile" modifier guarantees visibility of changes across threads and creates a happens-before memory barrier preventing instruction reordering.',
    ),

    // ==================== PYTHON ====================
    QuizBankQuestion(
      id: 'qb_py_001',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'Which of the following data structures is immutable in Python?',
      options: ['list', 'dict', 'set', 'tuple'],
      correctOptionIndex: 3,
      explanation: 'Tuples are immutable sequences in Python; their elements cannot be modified or reassigned after creation.',
    ),
    QuizBankQuestion(
      id: 'qb_py_002',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'What does the len() function return for the string "EduAI"?',
      options: ['4', '5', '6', 'Error'],
      correctOptionIndex: 1,
      explanation: '"EduAI" contains exactly 5 characters: E, d, u, A, I.',
    ),
    QuizBankQuestion(
      id: 'qb_py_003',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'What is the keyword used to define a generator function in Python?',
      options: ['generate', 'produce', 'yield', 'return'],
      correctOptionIndex: 2,
      explanation: 'The "yield" keyword transforms a regular Python function into a generator that yields values on demand.',
    ),
    QuizBankQuestion(
      id: 'qb_py_004',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'What is the output of print(type(lambda x: x * 2)) in Python?',
      options: ['<class "function">', '<class "lambda">', '<class "method">', '<class "object">'],
      correctOptionIndex: 0,
      explanation: 'Lambda functions are first-class anonymous functions and their type is <class "function">.',
    ),
    QuizBankQuestion(
      id: 'qb_py_005',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'What is Python\'s Global Interpreter Lock (GIL)?',
      options: [
        'A lock that secures Python file permissions',
        'A mutex that protects access to Python objects, preventing multiple native threads from executing Python bytecodes simultaneously in CPython',
        'A network firewall built into the Python socket module',
        'A package manager mechanism for preventing dependency conflicts'
      ],
      correctOptionIndex: 1,
      explanation: 'In CPython, the GIL is a mutex synchronizing execution of thread bytecodes so that only one thread executes Python bytecode at any given moment.',
    ),
    QuizBankQuestion(
      id: 'qb_py_006',
      topic: 'Python',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'In Python, what is the purpose of the __slots__ declaration in a class?',
      options: [
        'It speeds up database SQL queries',
        'It restricts allowed attributes and prevents the creation of an instance __dict__, saving memory',
        'It makes the class asynchronous',
        'It defines the number of CPU cores available to the class'
      ],
      correctOptionIndex: 1,
      explanation: '__slots__ prevents the default per-instance __dict__ from being allocated, significantly reducing memory footprint when instantiating millions of objects.',
    ),

    // ==================== C++ ====================
    QuizBankQuestion(
      id: 'qb_cpp_001',
      topic: 'C++',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'Which operator is used to access members of a structure through a pointer in C++?',
      options: ['.', '->', '*', '&'],
      correctOptionIndex: 1,
      explanation: 'The arrow operator (->) dereferences the pointer and accesses the structure/class member.',
    ),
    QuizBankQuestion(
      id: 'qb_cpp_002',
      topic: 'C++',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'Which of the following STL containers guarantees O(1) average lookup time?',
      options: ['std::map', 'std::unordered_map', 'std::vector', 'std::list'],
      correctOptionIndex: 1,
      explanation: 'std::unordered_map is implemented using a hash table, providing O(1) average lookup time, whereas std::map provides O(log n) using Red-Black trees.',
    ),
    QuizBankQuestion(
      id: 'qb_cpp_003',
      topic: 'C++',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'What is RAII (Resource Acquisition Is Initialization) in modern C++?',
      options: [
        'A design pattern where resources are tied to object lifetime and automatically cleaned up in destructors',
        'A compiler flag that enables parallel threading',
        'A library for parsing XML files',
        'A method of initializing global variables before main()'
      ],
      correctOptionIndex: 0,
      explanation: 'RAII binds resource lifecycle to the scope and lifetime of an object, guaranteeing deterministic cleanup via destructor invocations (e.g., std::unique_ptr).',
    ),

    // ==================== JAVASCRIPT ====================
    QuizBankQuestion(
      id: 'qb_js_001',
      topic: 'JavaScript',
      category: 'Programming',
      difficulty: 'Easy',
      question: 'What is the result of typeof NaN in JavaScript?',
      options: ['"undefined"', '"number"', '"NaN"', '"object"'],
      correctOptionIndex: 1,
      explanation: 'In JavaScript according to IEEE 754 float specs, typeof NaN is "number".',
    ),
    QuizBankQuestion(
      id: 'qb_js_002',
      topic: 'JavaScript',
      category: 'Programming',
      difficulty: 'Medium',
      question: 'What is a Closure in JavaScript?',
      options: [
        'A function bundled together with references to its surrounding lexical environment',
        'A method that closes a database connection',
        'A syntax error caused by unclosed parentheses',
        'A private variable inside a loop'
      ],
      correctOptionIndex: 0,
      explanation: 'A closure gives a function access to its outer scope even after the outer function has finished executing.',
    ),
    QuizBankQuestion(
      id: 'qb_js_003',
      topic: 'JavaScript',
      category: 'Programming',
      difficulty: 'Hard',
      question: 'Which queue in the JavaScript Event Loop has higher priority: the microtask queue or the macrotask (task) queue?',
      options: [
        'Macrotask queue',
        'Microtask queue',
        'Both have equal round-robin priority',
        'Dependent on browser network speed'
      ],
      correctOptionIndex: 1,
      explanation: 'The microtask queue (Promise callbacks, queueMicrotask) is completely drained before the next macrotask (setTimeout, setInterval) is executed.',
    ),

    // ==================== DSA ====================
    QuizBankQuestion(
      id: 'qb_dsa_001',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Easy',
      question: 'What is the time complexity of accessing an element in an array by its index?',
      options: ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
      correctOptionIndex: 0,
      explanation: 'Array elements are stored in contiguous memory locations, allowing direct memory address calculation in O(1) constant time.',
    ),
    QuizBankQuestion(
      id: 'qb_dsa_002',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Easy',
      question: 'Which data structure follows the Last-In First-Out (LIFO) principle?',
      options: ['Queue', 'Stack', 'LinkedList', 'Heap'],
      correctOptionIndex: 1,
      explanation: 'A Stack follows the LIFO principle where the element pushed last is the first to be popped.',
    ),
    QuizBankQuestion(
      id: 'qb_dsa_003',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Medium',
      question: 'What is the worst-case time complexity of QuickSort?',
      options: ['O(n log n)', 'O(n)', 'O(n^2)', 'O(2^n)'],
      correctOptionIndex: 2,
      explanation: 'When the chosen pivot continually partitions the array into highly unbalanced sub-arrays (e.g. sorted array with first element as pivot), QuickSort degrades to O(n^2).',
    ),
    QuizBankQuestion(
      id: 'qb_dsa_004',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Medium',
      question: 'Which graph traversal algorithm uses a FIFO Queue?',
      options: ['Depth First Search (DFS)', 'Breadth First Search (BFS)', 'Dijkstra with priority queue', 'Topological Sort with stack'],
      correctOptionIndex: 1,
      explanation: 'Breadth First Search (BFS) traverses level-by-level using a FIFO Queue to track unvisited adjacent vertices.',
    ),
    QuizBankQuestion(
      id: 'qb_dsa_005',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Hard',
      question: 'What is the time complexity to find the shortest path in a graph with non-negative weights using Dijkstra\'s algorithm with a Fibonacci heap?',
      options: ['O(V^2)', 'O(E + V log V)', 'O(E log V)', 'O(V * E)'],
      correctOptionIndex: 1,
      explanation: 'Using a Fibonacci heap, Dijkstra\'s algorithm achieves an optimal time complexity of O(E + V log V).',
    ),
    QuizBankQuestion(
      id: 'qb_dsa_006',
      topic: 'DSA',
      category: 'Computer Science',
      difficulty: 'Hard',
      question: 'In an AVL tree, what is the maximum permissible difference in heights between left and right subtrees of any node?',
      options: ['0', '1', '2', 'log(n)'],
      correctOptionIndex: 1,
      explanation: 'An AVL tree is a strictly height-balanced BST where the balance factor (height(left) - height(right)) must be -1, 0, or 1 for every node.',
    ),

    // ==================== DBMS ====================
    QuizBankQuestion(
      id: 'qb_dbms_001',
      topic: 'DBMS',
      category: 'Computer Science',
      difficulty: 'Easy',
      question: 'In relational databases, what does the SQL acronym ACID stand for?',
      options: [
        'Atomicity, Consistency, Isolation, Durability',
        'Accuracy, Control, Integrity, Data',
        'Authorization, Concurrency, Indexing, Delivery',
        'Automatic, Cached, Indexed, Distributed'
      ],
      correctOptionIndex: 0,
      explanation: 'ACID properties guarantee reliable database transactions: Atomicity, Consistency, Isolation, and Durability.',
    ),
    QuizBankQuestion(
      id: 'qb_dbms_002',
      topic: 'DBMS',
      category: 'Computer Science',
      difficulty: 'Medium',
      question: 'A relation is in Boyce-Codd Normal Form (BCNF) if and only if for every non-trivial functional dependency X -> Y:',
      options: [
        'Y is a prime attribute',
        'X is a superkey',
        'X is a foreign key',
        'Y contains no null values'
      ],
      correctOptionIndex: 1,
      explanation: 'BCNF requires that for every functional dependency X -> Y, the determinant X must be a superkey of the relation.',
    ),
    QuizBankQuestion(
      id: 'qb_dbms_003',
      topic: 'DBMS',
      category: 'Computer Science',
      difficulty: 'Hard',
      question: 'Which lock compatibility conflict occurs between Two-Phase Locking (2PL) shared (S) and exclusive (X) locks?',
      options: [
        'Shared and Shared locks are compatible; Shared and Exclusive locks conflict.',
        'Shared and Exclusive locks are always compatible.',
        'Exclusive locks can be acquired simultaneously by multiple readers.',
        'Neither Shared nor Exclusive locks conflict in Strict 2PL.'
      ],
      correctOptionIndex: 0,
      explanation: 'In 2PL, multiple transactions can hold shared (read) locks, but an exclusive (write) lock requires exclusive access, conflicting with both S and X locks.',
    ),

    // ==================== OPERATING SYSTEMS ====================
    QuizBankQuestion(
      id: 'qb_os_001',
      topic: 'Operating Systems',
      category: 'Computer Science',
      difficulty: 'Easy',
      question: 'Which component of the OS is responsible for loading the kernel into memory during boot?',
      options: ['File System', 'Bootloader', 'Shell', 'Device Driver'],
      correctOptionIndex: 1,
      explanation: 'The bootloader (e.g. GRUB, UEFI boot manager) initializes hardware and loads the kernel into primary memory.',
    ),
    QuizBankQuestion(
      id: 'qb_os_002',
      topic: 'Operating Systems',
      category: 'Computer Science',
      difficulty: 'Medium',
      question: 'Which of the following is NOT one of Coffman\'s four necessary conditions for a deadlock?',
      options: [
        'Mutual Exclusion',
        'Hold and Wait',
        'Preemption',
        'Circular Wait'
      ],
      correctOptionIndex: 2,
      explanation: 'The four conditions are Mutual Exclusion, Hold and Wait, No Preemption, and Circular Wait. Preemption breaks deadlock, so "No Preemption" is the required condition.',
    ),
    QuizBankQuestion(
      id: 'qb_os_003',
      topic: 'Operating Systems',
      category: 'Computer Science',
      difficulty: 'Hard',
      question: 'What is thrashing in an operating system?',
      options: [
        'When high CPU usage overheats the processor',
        'When the OS spends significantly more time swapping pages in and out of memory than executing processes',
        'A security attack that floods the process table',
        'Automatic deletion of temporary log files'
      ],
      correctOptionIndex: 1,
      explanation: 'Thrashing occurs when the working set of active processes exceeds available physical RAM, causing continuous page faults and disk I/O.',
    ),

    // ==================== COMPUTER NETWORKS ====================
    QuizBankQuestion(
      id: 'qb_net_001',
      topic: 'Computer Networks',
      category: 'Computer Science',
      difficulty: 'Easy',
      question: 'At which layer of the OSI model does the Internet Protocol (IP) operate?',
      options: ['Data Link Layer', 'Network Layer', 'Transport Layer', 'Session Layer'],
      correctOptionIndex: 1,
      explanation: 'The Network layer (Layer 3) handles logical packet addressing, routing, and IP protocol transmission.',
    ),
    QuizBankQuestion(
      id: 'qb_net_002',
      topic: 'Computer Networks',
      category: 'Computer Science',
      difficulty: 'Medium',
      question: 'What mechanism does TCP use to establish a reliable connection?',
      options: [
        'Two-way handshake',
        'Three-way handshake (SYN, SYN-ACK, ACK)',
        'Four-way ping exchange',
        'Stateless broadcast'
      ],
      correctOptionIndex: 1,
      explanation: 'TCP establishes reliable connections via a Three-Way Handshake: Client sends SYN, Server replies with SYN-ACK, Client responds with ACK.',
    ),
    QuizBankQuestion(
      id: 'qb_net_003',
      topic: 'Computer Networks',
      category: 'Computer Science',
      difficulty: 'Hard',
      question: 'What is the default subnet mask for a Class C IPv4 network in traditional classful addressing?',
      options: ['255.0.0.0', '255.255.0.0', '255.255.255.0', '255.255.255.255'],
      correctOptionIndex: 2,
      explanation: 'Class C IPv4 networks reserve 24 bits for the network ID and 8 bits for host IDs, giving a default subnet mask of 255.255.255.0 (/24).',
    ),

    // ==================== ARTIFICIAL INTELLIGENCE ====================
    QuizBankQuestion(
      id: 'qb_ai_001',
      topic: 'Artificial Intelligence',
      category: 'AI & ML',
      difficulty: 'Easy',
      question: 'Which test evaluates whether a machine can exhibit human-equivalent intelligent behavior?',
      options: ['Euler Test', 'Turing Test', 'Shannon Test', 'Moore Benchmark'],
      correctOptionIndex: 1,
      explanation: 'Proposed by Alan Turing in 1950, the Turing Test tests if a machine\'s conversation is indistinguishable from a human.',
    ),
    QuizBankQuestion(
      id: 'qb_ai_002',
      topic: 'Artificial Intelligence',
      category: 'AI & ML',
      difficulty: 'Medium',
      question: 'In the A* search algorithm, what does the heuristic function h(n) estimate?',
      options: [
        'The cost from the start node to node n',
        'The estimated lowest cost from node n to the goal node',
        'The total execution time of the algorithm',
        'The depth of node n in the search tree'
      ],
      correctOptionIndex: 1,
      explanation: 'In A* search f(n) = g(n) + h(n), where g(n) is the exact cost from start to n, and h(n) is an admissible heuristic estimate of the cost from n to the goal.',
    ),
    QuizBankQuestion(
      id: 'qb_ai_003',
      topic: 'Artificial Intelligence',
      category: 'AI & ML',
      difficulty: 'Hard',
      question: 'In adversarial game search, what does Alpha-Beta pruning optimize compared to standard Minimax?',
      options: [
        'It changes the minimax outcome to find a better move',
        'It prunes branches that cannot influence the final decision, reducing the search space without altering the evaluation',
        'It converts deep search into breadth-first search',
        'It eliminates the need for an evaluation function'
      ],
      correctOptionIndex: 1,
      explanation: 'Alpha-Beta pruning skips evaluating subtrees that cannot mathematically affect the final decision, potentially doubling the search depth.',
    ),

    // ==================== MACHINE LEARNING ====================
    QuizBankQuestion(
      id: 'qb_ml_001',
      topic: 'Machine Learning',
      category: 'AI & ML',
      difficulty: 'Easy',
      question: 'Which of the following algorithms is an example of Unsupervised Learning?',
      options: ['Linear Regression', 'Support Vector Machines', 'K-Means Clustering', 'Random Forest Classifier'],
      correctOptionIndex: 2,
      explanation: 'K-Means clustering groups unlabeled data into clusters without supervisor ground-truth targets.',
    ),
    QuizBankQuestion(
      id: 'qb_ml_002',
      topic: 'Machine Learning',
      category: 'AI & ML',
      difficulty: 'Medium',
      question: 'What symptom indicates a machine learning model is suffering from Overfitting?',
      options: [
        'High training error and high validation error',
        'Low training error but significantly higher validation/test error',
        'Equal training and validation error close to zero',
        'Slow training speed with large batch size'
      ],
      correctOptionIndex: 1,
      explanation: 'Overfitting occurs when a model memorizes noise in the training data, leading to low training error but poor generalization on test data.',
    ),
    QuizBankQuestion(
      id: 'qb_ml_003',
      topic: 'Machine Learning',
      category: 'AI & ML',
      difficulty: 'Hard',
      question: 'What technique adds an L2 regularization penalty proportional to the square of weight magnitudes?',
      options: ['Lasso Regression', 'Ridge Regression', 'Elastic Net with alpha=1', 'Dropout'],
      correctOptionIndex: 1,
      explanation: 'Ridge Regression adds an L2 penalty (sum of squared weights) to the loss function, shrinking weights toward zero without forcing them exactly to zero.',
    ),

    // ==================== DEEP LEARNING ====================
    QuizBankQuestion(
      id: 'qb_dl_001',
      topic: 'Deep Learning',
      category: 'AI & ML',
      difficulty: 'Easy',
      question: 'Which neural network architecture is primarily utilized for image processing and computer vision?',
      options: ['Recurrent Neural Networks (RNN)', 'Convolutional Neural Networks (CNN)', 'Markov Chains', 'Radial Basis Function Networks'],
      correctOptionIndex: 1,
      explanation: 'CNNs use convolutional layers and spatial weight sharing, making them highly effective for 2D image analysis.',
    ),
    QuizBankQuestion(
      id: 'qb_dl_002',
      topic: 'Deep Learning',
      category: 'AI & ML',
      difficulty: 'Medium',
      question: 'Which activation function is defined mathematically as f(x) = max(0, x)?',
      options: ['Sigmoid', 'Tanh', 'ReLU (Rectified Linear Unit)', 'Softmax'],
      correctOptionIndex: 2,
      explanation: 'ReLU returns x when x > 0 and 0 otherwise, overcoming the vanishing gradient problem in deep networks.',
    ),
    QuizBankQuestion(
      id: 'qb_dl_003',
      topic: 'Deep Learning',
      category: 'AI & ML',
      difficulty: 'Hard',
      question: 'What mechanism introduced in the paper "Attention Is All You Need" replaced recurrence in modern Transformer architectures?',
      options: [
        'Multi-Head Self-Attention',
        'Bidirectional LSTM Gates',
        'Stochastic Gradient Langevin Dynamics',
        'Gated Recurrent Units'
      ],
      correctOptionIndex: 0,
      explanation: 'Multi-Head Self-Attention calculates relationships across all tokens in parallel, replacing sequential recurrent steps.',
    ),

    // ==================== NLP ====================
    QuizBankQuestion(
      id: 'qb_nlp_001',
      topic: 'NLP',
      category: 'AI & ML',
      difficulty: 'Easy',
      question: 'What is the process of breaking a continuous text string into individual words or symbols called?',
      options: ['Stemming', 'Tokenization', 'Lemmatization', 'Parsing'],
      correctOptionIndex: 1,
      explanation: 'Tokenization segments raw text into meaningful smaller units such as words, punctuation, or subwords.',
    ),
    QuizBankQuestion(
      id: 'qb_nlp_002',
      topic: 'NLP',
      category: 'AI & ML',
      difficulty: 'Medium',
      question: 'In word embedding models like Word2Vec, what does semantic closeness in vector space represent?',
      options: [
        'Words with similar alphabetic spelling',
        'Words that appear in similar linguistic contexts and share similar meanings',
        'Words with the same syllable count',
        'Words with identical ASCII byte sums'
      ],
      correctOptionIndex: 1,
      explanation: 'Word2Vec maps semantic relationships into high-dimensional vector space where words sharing contextual usage have high cosine similarity.',
    ),
    QuizBankQuestion(
      id: 'qb_nlp_003',
      topic: 'NLP',
      category: 'AI & ML',
      difficulty: 'Hard',
      question: 'In large language model decoding, what does the "Temperature" hyperparameter control?',
      options: [
        'The physical hardware GPU temperature',
        'The sharpness of the probability distribution over token candidates during sampling',
        'The maximum context window length',
        'The rate of weight updates during fine-tuning'
      ],
      correctOptionIndex: 1,
      explanation: 'Lower temperature sharpens the softmax distribution toward greedy argmax selection, while higher temperature flattens it for more diverse outputs.',
    ),

    // ==================== HTML ====================
    QuizBankQuestion(
      id: 'qb_html_001',
      topic: 'HTML',
      category: 'Web Development',
      difficulty: 'Easy',
      question: 'Which HTML5 semantic element is used to represent self-contained, independent syndicatable content?',
      options: ['<div>', '<article>', '<section>', '<aside>'],
      correctOptionIndex: 1,
      explanation: 'The <article> tag specifies independent, self-contained content such as a blog post, news article, or forum entry.',
    ),
    QuizBankQuestion(
      id: 'qb_html_002',
      topic: 'HTML',
      category: 'Web Development',
      difficulty: 'Medium',
      question: 'Which attribute in the <script> tag downloads the script in parallel and executes it immediately when ready, out of document order?',
      options: ['defer', 'async', 'preload', 'type="module"'],
      correctOptionIndex: 1,
      explanation: '"async" downloads scripts asynchronously and executes them immediately upon receipt without preserving document order.',
    ),
    QuizBankQuestion(
      id: 'qb_html_003',
      topic: 'HTML',
      category: 'Web Development',
      difficulty: 'Hard',
      question: 'What is the purpose of the HTML meta tag: <meta name="viewport" content="width=device-width, initial-scale=1.0">?',
      options: [
        'It enforces desktop screen resolution on mobile devices',
        'It instructs mobile browsers to render the page width matching device pixels at 1:1 scale',
        'It speeds up image rendering via browser GPU acceleration',
        'It disables CSS stylesheets on legacy browsers'
      ],
      correctOptionIndex: 1,
      explanation: 'This viewport meta tag configures the responsive layout viewport so mobile browsers render CSS responsive queries accurately.',
    ),

    // ==================== CSS ====================
    QuizBankQuestion(
      id: 'qb_css_001',
      topic: 'CSS',
      category: 'Web Development',
      difficulty: 'Easy',
      question: 'Which CSS property is used to change the background color of an element?',
      options: ['color', 'bgcolor', 'background-color', 'surface-color'],
      correctOptionIndex: 2,
      explanation: '"background-color" sets the background fill color of any HTML element.',
    ),
    QuizBankQuestion(
      id: 'qb_css_002',
      topic: 'CSS',
      category: 'Web Development',
      difficulty: 'Medium',
      question: 'In the CSS Box Model, what is the correct order from outermost to innermost?',
      options: [
        'Margin -> Border -> Padding -> Content',
        'Padding -> Margin -> Border -> Content',
        'Border -> Margin -> Padding -> Content',
        'Margin -> Padding -> Border -> Content'
      ],
      correctOptionIndex: 0,
      explanation: 'From the outside in: Margin clears space outside the border, followed by Border, Padding inside the border, and Content.',
    ),
    QuizBankQuestion(
      id: 'qb_css_003',
      topic: 'CSS',
      category: 'Web Development',
      difficulty: 'Hard',
      question: 'In CSS specificity, which selector combination has the highest priority?',
      options: [
        'Inline style attribute (e.g. style="...")',
        'An ID selector (#navbar)',
        'Three chained class selectors (.btn.primary.active)',
        'An element selector with 10 pseudo-elements'
      ],
      correctOptionIndex: 0,
      explanation: 'Inline styles hold specificity (1, 0, 0, 0), which overrides IDs (0, 1, 0, 0), classes (0, 0, 1, 0), and elements unless !important is used.',
    ),

    // ==================== REACT ====================
    QuizBankQuestion(
      id: 'qb_react_001',
      topic: 'React',
      category: 'Web Development',
      difficulty: 'Easy',
      question: 'Which built-in React hook is used to manage local component state?',
      options: ['useEffect', 'useState', 'useContext', 'useReducer'],
      correctOptionIndex: 1,
      explanation: 'useState declares a state variable and a setter function for functional components.',
    ),
    QuizBankQuestion(
      id: 'qb_react_002',
      topic: 'React',
      category: 'Web Development',
      difficulty: 'Medium',
      question: 'What is the purpose of passing an empty dependency array [] to useEffect()?',
      options: [
        'It causes the effect to run on every render',
        'It runs the effect only once when the component mounts',
        'It cancels the component render completely',
        'It throws a compile-time warning in React 18'
      ],
      correctOptionIndex: 1,
      explanation: 'An empty dependency array indicates no state/props dependencies, causing the effect to run only once after initial mount.',
    ),
    QuizBankQuestion(
      id: 'qb_react_003',
      topic: 'React',
      category: 'Web Development',
      difficulty: 'Hard',
      question: 'What does React Fiber enable in the React reconciliation architecture?',
      options: [
        'Direct DOM manipulation without virtual DOM',
        'Incremental rendering with interruptible, prioritized work scheduling',
        'Automatic server-side SQL compilation',
        'WebAssembly compilation for all JavaScript functions'
      ],
      correctOptionIndex: 1,
      explanation: 'React Fiber is a reimplementation of React\'s core algorithm that allows splitting rendering work into chunks and prioritizing user input.',
    ),

    // ==================== QUANTITATIVE APTITUDE ====================
    QuizBankQuestion(
      id: 'qb_quant_001',
      topic: 'Quantitative Aptitude',
      category: 'Aptitude',
      difficulty: 'Easy',
      question: 'If a product priced at \$80 is sold at a 25% discount, what is the selling price?',
      options: ['\$55', '\$60', '\$65', '\$70'],
      correctOptionIndex: 1,
      explanation: 'Discount = 25% of 80 = \$20. Selling Price = 80 - 20 = \$60.',
    ),
    QuizBankQuestion(
      id: 'qb_quant_002',
      topic: 'Quantitative Aptitude',
      category: 'Aptitude',
      difficulty: 'Medium',
      question: 'A train 150 meters long passes an electric pole in 15 seconds. What is the speed of the train in km/h?',
      options: ['30 km/h', '36 km/h', '42 km/h', '45 km/h'],
      correctOptionIndex: 1,
      explanation: 'Speed = Distance / Time = 150m / 15s = 10 m/s. In km/h = 10 * (18 / 5) = 36 km/h.',
    ),
    QuizBankQuestion(
      id: 'qb_quant_003',
      topic: 'Quantitative Aptitude',
      category: 'Aptitude',
      difficulty: 'Hard',
      question: 'A can complete a project in 12 days, and B can complete it in 18 days. If they work together for 4 days, what fraction of work is left?',
      options: ['1/3', '4/9', '5/9', '2/3'],
      correctOptionIndex: 1,
      explanation: 'Combined 1-day rate = (1/12 + 1/18) = 5/36. In 4 days, they complete 4 * (5/36) = 20/36 = 5/9. Remaining work = 1 - 5/9 = 4/9.',
    ),

    // ==================== LOGICAL REASONING ====================
    QuizBankQuestion(
      id: 'qb_lr_001',
      topic: 'Logical Reasoning',
      category: 'Aptitude',
      difficulty: 'Easy',
      question: 'Find the next number in the series: 3, 6, 12, 24, 48, ...',
      options: ['72', '84', '96', '108'],
      correctOptionIndex: 2,
      explanation: 'Each term is multiplied by 2. 48 * 2 = 96.',
    ),
    QuizBankQuestion(
      id: 'qb_lr_002',
      topic: 'Logical Reasoning',
      category: 'Aptitude',
      difficulty: 'Medium',
      question: 'Pointing to a photograph, a woman says: "He is the son of the only daughter of my father." How is the boy in the photograph related to the woman?',
      options: ['Brother', 'Son', 'Nephew', 'Uncle'],
      correctOptionIndex: 1,
      explanation: 'The only daughter of the woman\'s father is the woman herself. Therefore, the boy is her son.',
    ),
    QuizBankQuestion(
      id: 'qb_lr_003',
      topic: 'Logical Reasoning',
      category: 'Aptitude',
      difficulty: 'Hard',
      question: 'In a certain code, "FLOWER" is written as "UOLDVI". How is "GARDEN" written in that code?',
      options: ['TZIVWM', 'TYIUWN', 'SZIUMX', 'TZIVWN'],
      correctOptionIndex: 0,
      explanation: 'Each letter is substituted by its reverse alphabetical counterpart (A <-> Z, B <-> Y). G <-> T, A <-> Z, R <-> I, D <-> W, E <-> V, N <-> M.',
    ),

    // ==================== GENERAL KNOWLEDGE ====================
    QuizBankQuestion(
      id: 'qb_gk_001',
      topic: 'General Knowledge',
      category: 'General Knowledge',
      difficulty: 'Easy',
      question: 'Who is widely regarded as the "Father of the Computer"?',
      options: ['Charles Babbage', 'Alan Turing', 'John von Neumann', 'Blaise Pascal'],
      correctOptionIndex: 0,
      explanation: 'Charles Babbage designed the Analytical Engine and Difference Engine, earning him the title "Father of the Computer".',
    ),
    QuizBankQuestion(
      id: 'qb_gk_002',
      topic: 'General Knowledge',
      category: 'General Knowledge',
      difficulty: 'Medium',
      question: 'Which space agency launched the James Webb Space Telescope (JWST)?',
      options: ['NASA (in international partnership with ESA and CSA)', 'ISRO', 'Roscosmos', 'JAXA'],
      correctOptionIndex: 0,
      explanation: 'NASA launched JWST in December 2021 in partnership with the European Space Agency (ESA) and the Canadian Space Agency (CSA).',
    ),
    QuizBankQuestion(
      id: 'qb_gk_003',
      topic: 'General Knowledge',
      category: 'General Knowledge',
      difficulty: 'Hard',
      question: 'In computer science history, which year was the World Wide Web publicly introduced by Tim Berners-Lee at CERN?',
      options: ['1983', '1989', '1991', '1995'],
      correctOptionIndex: 2,
      explanation: 'While proposed in 1989, the World Wide Web became publicly accessible on the internet in August 1991.',
    ),
  ];

  static List<QuizBankQuestion> getQuestionsForTopic(String topic, {String? difficulty}) {
    return initialQuestions.where((q) {
      final matchesTopic = q.topic.toLowerCase() == topic.toLowerCase();
      if (difficulty == null || difficulty.isEmpty) return matchesTopic;
      return matchesTopic && q.difficulty.toLowerCase() == difficulty.toLowerCase();
    }).toList();
  }

  static List<QuizTopicMeta> getTopicsForCategory(String category) {
    if (category == 'All') return topics;
    return topics.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList();
  }
}
