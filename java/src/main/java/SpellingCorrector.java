import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;


public class SpellingCorrector {
	private static final String alphabet = "abcdefghijklmnopqrstuvwxyz";
	private Map<String,Integer> languageModel = new HashMap<String,Integer>();

	public SpellingCorrector(){
		buildLanguageModel();
	}

	public String correct(String word){
		Set<String> candidatesSet = findLikelyCandidates(word);

		if (candidatesSet.size() == 1){
			return candidatesSet.iterator().next();
		}

		return findMostLikelyCandidateInLanguageModel(candidatesSet);

	}

	private String findMostLikelyCandidateInLanguageModel(Set<String> candidatesSet) {
		int highScore = 0;
		String selectedWord = null;
		for (String wordCandidate : candidatesSet){
			int score = languageModel.get(wordCandidate);
			if (score > highScore){
				highScore = score;
				selectedWord = wordCandidate;
			}
		}
		return selectedWord;
	}

	public Set<String> applySingleCharacterDeletions(String word) {
		Set<String> deletes = new HashSet<String>();
		for (int i = 0; i < word.length(); i++){
			deletes.add(new StringBuffer(word).deleteCharAt(i).toString());
		}
		return deletes;
	}

	public Set<String> applyTranspositions(String word){
		Set<String> transpositions = new HashSet<String>();
		for (int i = 0; i < word.length() - 1; i++){
			transpositions.add(transpose(word, i));
		}
		return transpositions;
	}

	private String transpose(String word, int index){
		return new StringBuilder(word).
				deleteCharAt(index).
				insert(index+1, word.charAt(index)).
				toString();
	}

	public Set<String> applyOneLetterTypeos(String word){
		Set<String> alterations = new HashSet<String>();
		for (int i = 0; i < word.length(); i++){
			for(int j = 0; j < alphabet.length(); j++){
				String replacement = String.valueOf(alphabet.charAt(j));
				alterations.add(
						new StringBuilder(word).replace(i, i + 1, replacement).toString());
			}
		}
		return alterations;
	}

	public Set<String> applyInserts(String word){
		Set<String> inserts = new HashSet<String>();
		for (int i = 0; i <= word.length(); i++){
			for(int j = 0; j < alphabet.length(); j++){
				inserts.add(new StringBuilder(word).insert(i, alphabet.charAt(j)).toString());
			}
		}
		return inserts;
	}

	public Set<String> applyEdits(String word){
		Set<String> edits = new HashSet<String>();
		edits.addAll(applySingleCharacterDeletions(word));
		edits.addAll(applyTranspositions(word));
		edits.addAll(applyOneLetterTypeos(word));
		edits.addAll(applyInserts(word));
		return edits;
	}


	private Set<String> filterOutNonWords(Set<String> words){
		Set<String> filteredWords = new HashSet<String>();
		for (String word : words){
			if (isWordInLanguageModel(word)){
				filteredWords.add(word);
			}
		}
		return filteredWords;
	}

	private boolean isWordInLanguageModel(String word){
		return languageModel.containsKey(word);
	}


	public Set<String> findLikelyCandidates(String word) {

		Set<String> wordSet = new HashSet<String>();
		wordSet.add(word);
		if (isWordInLanguageModel(word)) {
			return wordSet;
		}

		Set<String> edits = applyEdits(word);
		Set<String> candidates = filterOutNonWords(edits);
		if (!candidates.isEmpty()) {
			return candidates;
		}

		Set<String> secondOrderEdits = applyEditsToSet(edits);
		candidates = filterOutNonWords(secondOrderEdits);
		if (!candidates.isEmpty()) {
			return candidates;
		}

		return wordSet;
	}

	private Set<String> applyEditsToSet(Set<String> words) {
		Set<String> edits = new HashSet<String>();
		for (String word : words){
			edits.addAll(applyEdits(word));
		}
		return edits;
	}

	public void buildLanguageModel() {
		try {
			BufferedReader input = new BufferedReader(new FileReader("../big.txt"));
			try {
				String line;
				while ((line = input.readLine()) != null) {
					StringTokenizer tok = new StringTokenizer(line);
					while (tok.hasMoreElements()) {
						String word = (String) tok.nextElement();
						if (languageModel.get(word) == null) {
							 languageModel.put(word, 1);
						}
						else{
							languageModel.put(word, languageModel.get(word) + 1);
						}
					}
				}
			} finally {
				input.close();
			}
		} catch (IOException ex) {
			throw new RuntimeException(ex);
		}
	}


}
