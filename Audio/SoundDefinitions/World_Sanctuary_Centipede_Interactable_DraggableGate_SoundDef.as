
UCLASS(Abstract)
class UWorld_Sanctuary_Centipede_Interactable_DraggableGate_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGateChainGrabbed(FSanctuaryCentipedeGateChainGrabbedData Params){}

	UFUNCTION(BlueprintEvent)
	void OnGateChainReleased(FSanctuaryCentipedeGateChainReleasedData Params){}

	/* END OF AUTO-GENERATED CODE */

	ADraggableGateActor Gate;
	private float PreviousCombinedAlpha = 0.0;

	private float LeftAlpha = 0.0;
	private float RightAlpha = 0.0;
	private float CombinedAlpha = 0.0;
	private float DiffAlpha = 0.0;
	private float DirectionSign = 0.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Gate = Cast<ADraggableGateActor>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	void HasPassedAttachPoint(bool&out Left, bool&out Right)
	{
		Left = Gate.bChain1Locked;
		Right = Gate.bChain2Locked;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const float CurrLeftAlpha = Gate.Chain1TranslateComp.GetCurrentAlphaBetweenConstraints().Size();
		LeftAlpha = CurrLeftAlpha + (Gate.bChain1Locked ? (0.6 * (1 - CurrLeftAlpha)) : 0.0);

		const float CurrRightAlpha = Gate.Chain2TranslateComp.GetCurrentAlphaBetweenConstraints().Size();
		RightAlpha = CurrRightAlpha + (Gate.bChain2Locked ? (0.6 * (1 - CurrRightAlpha)) : 0.0);
		
		CombinedAlpha = (LeftAlpha + RightAlpha) / 2;

		DiffAlpha = LeftAlpha - RightAlpha;

		DirectionSign = Math::IsNearlyEqual(CombinedAlpha, PreviousCombinedAlpha, KINDA_SMALL_NUMBER) ? 0.0 : Math::Sign(CombinedAlpha - PreviousCombinedAlpha);			
		PreviousCombinedAlpha = CombinedAlpha;

		if(IsDebugging())
		{
			PrintToScreenScaled("Left: " + LeftAlpha, 0.f, Scale = 3.f);
			PrintToScreenScaled("Right: " + RightAlpha, 0.f, Scale = 3.f);
			PrintToScreenScaled("Combined: " + CombinedAlpha, 0.f, Scale = 3.f);
			PrintToScreenScaled("Diff: " + DiffAlpha, 0.f, Scale = 3.f);
			PrintToScreenScaled("Direction: " + DirectionSign, 0.f);
		}
	}

	UFUNCTION(BlueprintPure)
	void GetGatePullAlpha(float&out Left, float&out Right, float&out Combined, float&out Diff, float&out Direction) const
	{
		Left = LeftAlpha;
		Right = RightAlpha;
		Combined = CombinedAlpha;
		Diff = DiffAlpha;
		Direction = DirectionSign;
	}
}