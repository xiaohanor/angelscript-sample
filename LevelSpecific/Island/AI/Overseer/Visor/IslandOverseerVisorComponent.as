class UIslandOverseerVisorComponent : USceneComponent
{
	bool bDisabled;
	bool bOpen;
	bool bOpening;
	bool bClosing;
	float OpenDuration = 0.75;
	float CloseDuration = 0.75;

	void Open()
	{
		bOpening = true;
		bClosing = false;
	}

	void Close()
	{
		bClosing = true;
		bOpening = false;
	}
}