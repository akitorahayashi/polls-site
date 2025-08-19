from django.test import TestCase
from django.urls import reverse

from apps.polls.tests.helpers import create_choice, create_question


class ResultsViewTests(TestCase):
    def test_future_question_results_returns_404(self):
        """
        The results view of a question with a pub_date in the future
        returns a 404 not found.
        """
        future_question = create_question("Future question.", days=5)
        create_choice(future_question, "Choice 1")
        url = reverse("polls:results", args=(future_question.id,))
        response = self.client.get(url)
        self.assertEqual(response.status_code, 404)

    def test_past_question_results_displays_question(self):
        """
        The results view of a question with a pub_date in the past
        displays the question's text.
        """
        past_question = create_question("Past Question.", days=-5)
        create_choice(past_question, "Choice 1")
        url = reverse("polls:results", args=(past_question.id,))
        response = self.client.get(url)
        self.assertContains(response, past_question.question_text)
