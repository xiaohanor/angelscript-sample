
UCLASS(Abstract)
class UUI_DialogMessages_SoundDef : UUI_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	
	UFUNCTION()
	void OnMessageDialog(FMessageDialogData Data)
	{
		// Register to the different options of the message dialog.
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnMessageDialog {Data.Widget}", Duration = 10);
		#endif

		RegisterToMessageDialogWidget(Data.Widget);
	}

}