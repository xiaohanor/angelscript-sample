struct FLightSeekerSwingyAnimationData
{
	AHazePlayerCharacter Player;
	FVector LastPosition;
}

class ULightSeekerSwingyHeadAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerSwingyHeadAnimation");

	default TickGroup = EHazeTickGroup::Gameplay;

	ALightSeeker LightSeeker;

	TArray<FLightSeekerSwingyAnimationData> AttachedPlayers;
	UGrappleLaunchPointComponent GrappleLaunchComp;
	USwingPointComponent SwingComp;

	float TargetUpMagnitude = 0;
	float TargetRightMagnitude = 0;
	float BouncebackFactor = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		GrappleLaunchComp = UGrappleLaunchPointComponent::Get(Owner);
		if (GrappleLaunchComp != nullptr)
		{
			GrappleLaunchComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerAttachedToGrappleLaunchPoint");
			GrappleLaunchComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnPlayerDetachedToGrappleLaunchPoint");
		}
		SwingComp = USwingPointComponent::Get(Owner);
		if (SwingComp != nullptr)
		{
			SwingComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttachedToSwingPoint");
			SwingComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetachedToSwingPoint");
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LightSeeker.bIsGrappling)
			return true;

		if (LightSeeker.bIsSwinging)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LightSeeker.bIsSwinging && !LightSeeker.bIsGrappling)
			return false;

		if (BouncebackFactor > 0.0)
			return false;

		if (LightSeeker.AnimationDownUpGradient.Velocity < SMALL_NUMBER)
			return false;

		if (LightSeeker.AnimationLeftRightGradient.Velocity < SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BouncebackFactor <= 0.0)
			CalculateUpRightGradients();
		else if (LightSeeker.AnimationDownUpGradient.Value >= TargetUpMagnitude - KINDA_SMALL_NUMBER && LightSeeker.AnimationDownUpGradient.Value < TargetUpMagnitude + KINDA_SMALL_NUMBER)
		{
			BouncebackFactor *= 0.7;
			if (BouncebackFactor < 0.2)
				BouncebackFactor = 0.0;
			TargetUpMagnitude *= -BouncebackFactor;
			TargetRightMagnitude *= -BouncebackFactor;
		}

		const float BouncyDuration = 1.0;
		LightSeeker.AnimationDownUpGradient.AccelerateTo(TargetUpMagnitude, BouncyDuration, DeltaTime);
		LightSeeker.AnimationLeftRightGradient.AccelerateTo(TargetRightMagnitude, BouncyDuration, DeltaTime);

		if (LightSeeker.bDebugging)
		{
			PrintToScreen("Right Magnitude " + LightSeeker.AnimationLeftRightGradient.Value);
			PrintToScreen("Up Magnitude " + LightSeeker.AnimationDownUpGradient.Value);
			Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, LightSeeker.Head.WorldLocation + LightSeeker.Head.RightVector * 500 *LightSeeker.AnimationLeftRightGradient.Value, FLinearColor::Red, 10);
			Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, LightSeeker.Head.WorldLocation + LightSeeker.Head.UpVector * 500 *LightSeeker.AnimationDownUpGradient.Value, FLinearColor::LucBlue, 10);
		}
	}

	private void CalculateUpRightGradients()
	{
		FVector TotalAffection = FVector::ZeroVector;
		float UpMagnitude = 0.0;
		float RightMagnitude = 0.0;
		if (AttachedPlayers.Num() > 0)
		{
			for (int i = 0; i < AttachedPlayers.Num(); ++i)
			{
				FVector PlayerCurrentPosition = AttachedPlayers[i].Player.GetActorLocation();
				FVector PlayerMovementSinceLast = AttachedPlayers[i].LastPosition - PlayerCurrentPosition;
				FVector HeadToPlayer = PlayerCurrentPosition - LightSeeker.Head.WorldLocation;
				TotalAffection += HeadToPlayer.GetSafeNormal() * PlayerMovementSinceLast.Size();
				AttachedPlayers[i].LastPosition = AttachedPlayers[i].Player.GetActorLocation();
			}
			RightMagnitude = LightSeeker.Head.RightVector.DotProduct(TotalAffection.GetSafeNormal()); // -1 to 1 space
			UpMagnitude = (LightSeeker.Head.UpVector).DotProduct(TotalAffection.GetSafeNormal()); // 0-1 space
			float UpAffectionMagnitude = Math::Clamp(TotalAffection.Size() * LightSeeker.SwingUpDownAffectAnimationMultiplier, 0.0, 1.0);
			float RightAffectionMagnitude = Math::Clamp(TotalAffection.Size() * LightSeeker.SwingLeftRightAffectAnimationMultiplier, 0.0, 1.0);
			RightMagnitude *= UpAffectionMagnitude;
			UpMagnitude *= RightAffectionMagnitude;
		}
		TargetRightMagnitude = RightMagnitude;
		TargetUpMagnitude = UpMagnitude;
	}

	UFUNCTION()
	void OnPlayerAttachedToGrappleLaunchPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrappleLaunchPoint)
	{
		FLightSeekerSwingyAnimationData NewData;
		NewData.Player = Player;
		NewData.LastPosition = Player.GetActorLocation();
		AttachedPlayers.Add(NewData);
		LightSeeker.bIsGrappling = true;
		BouncebackFactor = 0.7;
	}

	UFUNCTION()
	void OnPlayerDetachedToGrappleLaunchPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrappleLaunchPoint)
	{
		if (AttachedPlayers.Num() == 1)
		{
			TargetRightMagnitude *= -1;
			TargetUpMagnitude *= -1;
			BouncebackFactor = 0.7;
		}

		for (int i = 0; i < AttachedPlayers.Num(); ++i)
		{
			if (AttachedPlayers[i].Player == Player)
			{
				AttachedPlayers.RemoveAt(i);
				break;
			}
		}
		if (AttachedPlayers.Num() == 0)
			LightSeeker.bIsGrappling = false;
	}

	UFUNCTION()
	void OnPlayerAttachedToSwingPoint(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		FLightSeekerSwingyAnimationData NewData;
		NewData.Player = Player;
		NewData.LastPosition = Player.GetActorLocation();
		AttachedPlayers.Add(NewData);
		LightSeeker.bIsSwinging = true;
		BouncebackFactor = 0.0;
	}

	UFUNCTION()
	void OnPlayerDetachedToSwingPoint(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		if (AttachedPlayers.Num() == 1)
		{
			TargetRightMagnitude *= -1;
			TargetUpMagnitude *= -1;
			BouncebackFactor = 0.7;
		}
		
		for (int i = 0; i < AttachedPlayers.Num(); ++i)
		{
			if (AttachedPlayers[i].Player == Player)
			{
				AttachedPlayers.RemoveAt(i);
				break;
			}
		}
		if (AttachedPlayers.Num() == 0)
			LightSeeker.bIsSwinging = false;
	}
};