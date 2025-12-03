
UCLASS(Abstract)
class UGameplay_Character_Prison_ArenaBoss_FlameThrower_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void FlameThrowerStateEnded(){}

	UFUNCTION(BlueprintEvent)
	void FlameThrowerStateWindDown(){}

	UFUNCTION(BlueprintEvent)
	void FlameThrowerStopped(FArenaBossFlameThrowerData Data){}

	UFUNCTION(BlueprintEvent)
	void FlameThrowerStarted(FArenaBossFlameThrowerData Data){}

	UFUNCTION(BlueprintEvent)
	void FlameThrowerStateEntered(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	float ConeAngle = 15;
	
	UPROPERTY()
	float ConeLength = 2500;

	UPROPERTY()
	float ConeVerticalOffset = -50;

	UPROPERTY()
	float VerticalAngleOffset = 5;

	TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(2);

	UHazeAudioComponent ActiveHand = nullptr;
	TArray<UHazeAudioListenerComponentBase> Listeners;

	private float LastAngle = 0;
	// A calculated approximation
	private float RadiusIncreaseByUnit;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Audio::GetListeners(this, Listeners);
	}

	UFUNCTION()
	void SetActiveHand(UHazeAudioComponent LeftOrRightHand)
	{
		ActiveHand = LeftOrRightHand;
		UpdatePositions();
	}

	// Good enough
	FVector GetClosestPositionOnCone(const FVector& Start, const FVector& End, const FVector& Point)
	{
		auto ConeDirection = (Point - Start).ConstrainToCone(End-Start, Math::DegreesToRadians(ConeAngle));
		auto ClosestPointOnConeEdge = Math::ClosestPointOnLine(Start, Start + ConeDirection.GetSafeNormal() * Start.Distance(End), Point);
		return ClosestPointOnConeEdge;
	}

	UFUNCTION()
	void UpdatePositions()
	{
		if (ActiveHand == nullptr)
			return;

		/*
			FVector TraceLoc = Boss.Mesh.GetSocketLocation(CurrentSocket);
			FVector Dir = Boss.Mesh.GetSocketRotation(CurrentSocket).UpVector;
			Dir = Dir.ConstrainToPlane(FVector::UpVector);
			TraceLoc += Dir * 5000.0;
			TraceLoc -= FVector::UpVector * 200.0;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseBoxShape(5000.0, 150.0, 500.0, FQuat(Dir.Rotation()));

		*/
		// See UArenaBossFlameThrowerCapability for it's current settings. Above is the snippet for current implementation of this SD.

		auto Forward = ActiveHand.ForwardVector.RotateTowards(ActiveHand.UpVector, VerticalAngleOffset);
		auto ConeStart = ActiveHand.WorldLocation + ActiveHand.UpVector * ConeVerticalOffset;
		auto ConeEnd = ConeStart +Forward * ConeLength;
		
		#if TEST
		if (IsDebugging())
			Debug::DrawDebugCone(ConeStart, Forward, ConeLength, ConeAngle, ConeAngle);
		#endif

		for (int i=0; i < Listeners.Num(); ++i)
		{
			auto NewPosition = GetClosestPositionOnCone(ConeStart, ConeEnd, Listeners[i].WorldLocation);
			SoundPositions[i].SetPosition(NewPosition);
			#if TEST
			if (IsDebugging())
				Debug::DrawDebugPoint(NewPosition, 40);
			#endif
		}

		ActiveHand.SetMultipleSoundPositions(SoundPositions);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Only updates it's positions when playing events.
		if (HasActiveEvents() == false)
			return;

		UpdatePositions();
	}
}