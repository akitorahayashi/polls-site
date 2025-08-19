import datetime

from django.utils import timezone

from apps.polls.models import Choice, Question


def create_question(question_text, days):
    """
    Create a question with the given `question_text` and published the
    given number of `days` offset to now (negative for questions published
    in the past, positive for questions that have yet to be published).
    """
    time = timezone.now() + datetime.timedelta(days=days)
    return Question.objects.create(question_text=question_text, pub_date=time)


def create_choice(question, choice_text):
    """
    Create a choice with the given `choice_text` for the given `question`.
    """
    return Choice.objects.create(question=question, choice_text=choice_text)
