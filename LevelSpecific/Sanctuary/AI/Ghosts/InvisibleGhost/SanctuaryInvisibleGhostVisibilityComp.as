event void FSanctuaryInvisibleGhostVisibilityIndicateStartSignature();
event void FSanctuaryInvisibleGhostVisibilityIndicateEndSignature();
event void FSanctuaryInvisibleGhostVisibilityRevealSignature();
event void FSanctuaryInvisibleGhostVisibilityHideSignature();

class USanctuaryInvisibleGhostVisibilityComp : UActorComponent
{
	FSanctuaryInvisibleGhostVisibilityIndicateStartSignature OnIndicateStart;
	FSanctuaryInvisibleGhostVisibilityIndicateEndSignature OnIndicateEnd;
	FSanctuaryInvisibleGhostVisibilityRevealSignature OnReveal;
	FSanctuaryInvisibleGhostVisibilityHideSignature OnHide;

	bool bVisible;
	bool bIndicating;
	float IndicateTime;

	void StartIndicate()
	{
		bIndicating = true;		
		OnIndicateStart.Broadcast();		
	}

	void StopIndicate()
	{
		bIndicating = false;
		IndicateTime = Time::GetGameTimeSeconds();
		OnIndicateEnd.Broadcast();
	}

	void Reveal()
	{
		bVisible = true;
		OnReveal.Broadcast();
	}

	void Hide()
	{
		bVisible = false;
		OnHide.Broadcast();
	}
}