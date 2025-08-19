from django.test import TestCase
from django.urls import reverse

from apps.polls.tests.helpers import create_choice, create_question


class QuestionDetailViewTests(TestCase):
    def test_future_question(self):
        """
        The detail view of a question with a pub_date in the future
        returns a 404 not found.
        """
        future_question = create_question(question_text="Future question.", days=5)
        create_choice(future_question, "Choice 1")
        url = reverse("polls:detail", args=(future_question.id,))
        response = self.client.get(url)
        self.assertEqual(response.status_code, 404)

    def test_past_question(self):
        """
        The detail view of a question with a pub_date in the past
        displays the question's text.
        """
        past_question = create_question(question_text="Past Question.", days=-5)
        create_choice(past_question, "Choice 1")
        url = reverse("polls:detail", args=(past_question.id,))
        response = self.client.get(url)
        self.assertContains(response, past_question.question_text)

    def test_question_with_no_choices_returns_404(self):
        """
        The detail view of a question with no choices returns a 404.
        """
        question = create_question(question_text="Question with no choices.", days=-5)
        url = reverse("polls:detail", args=(question.id,))
        response = self.client.get(url)
        self.assertEqual(response.status_code, 404)


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
