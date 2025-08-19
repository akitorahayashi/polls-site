from django.test import TestCase
from django.urls import reverse

from apps.polls.tests.helpers import create_choice, create_question


class VoteViewTests(TestCase):
    def test_vote_increments_choice_votes(self):
        """
        Voting for a choice increments its vote count by 1.
        """
        question = create_question("Test question", days=-1)
        choice = create_choice(question, "Test choice")
        self.assertEqual(choice.votes, 0)

        url = reverse("polls:vote", args=(question.id,))
        response = self.client.post(url, {"choice": choice.id})

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, reverse("polls:results", args=(question.id,)))

        choice.refresh_from_db()
        self.assertEqual(choice.votes, 1)

    def test_vote_without_selecting_choice_returns_error(self):
        """
        Voting without selecting a choice redisplays the detail page with an error message.
        """
        question = create_question("Test question", days=-1)
        choice = create_choice(question, "Test choice")
        url = reverse("polls:vote", args=(question.id,))
        response = self.client.post(url)

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "You didn&#x27;t select a choice.")

        choice.refresh_from_db()
        self.assertEqual(choice.votes, 0)
