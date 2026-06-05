import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

/**
 * Automatically populates a game room with questions from an external API
 * when the room is created.
 */
export const onRoomCreated = onDocumentCreated("gameRooms/{roomId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    try {
      // Fetch 10 multiple-choice questions from Open Trivia DB
      const response = await axios.get(
        "https://opentdb.com/api.php?amount=10&type=multiple"
      );

      // Define a type for the result to avoid 'any'
      interface TriviaQuestion {
        question: string;
        correct_answer: string;
        incorrect_answers: string[];
      }

      const questions = response.data.results.map((q: TriviaQuestion) => ({
        question: q.question,
        correct_answer: q.correct_answer,
        incorrect_answers: q.incorrect_answers,
      }));

      // Update the room with real questions
      await snap.ref.update({
        questions: questions,
        status: "waiting", // Ensure it's ready for players
      });
      console.log(`Populated questions for room: ${event.params.roomId}`);
    } catch (error) {
      console.error("Error fetching questions:", error);
    }
  });
