UFUNCTION(Category = "Message Dialog")
void ShowPopupMessage(FMessageDialog Message, FInstigator Instigator)
{
	auto Dialogs = UMessageDialogSingleton::Get();
	Dialogs.AddMessage(Message, Instigator);
}

UFUNCTION(Category = "Message Dialog")
void ClosePopupMessageByInstigator(FInstigator Instigator)
{
	auto Dialogs = UMessageDialogSingleton::Get();
	Dialogs.CloseMessageWithInstigator(Instigator);
}

UFUNCTION(Category = "Message Dialog")
bool IsMessageDialogShown()
{
	auto Dialogs = UMessageDialogSingleton::Get();
	return Dialogs.Messages.Num() != 0;
}