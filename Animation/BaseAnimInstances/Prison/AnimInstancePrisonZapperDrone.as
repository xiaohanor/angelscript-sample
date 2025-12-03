namespace PrisonZapperAnimTags
{
	const FName Shooting = n"Shooting";
	const FName HitReaction = n"HitReaction";
}

class UAnimInstancePrisonZapperDrone : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Shoot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeAcceleratedRotator BankingSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator GunRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendspaceValueX;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HitReactionAlpha;

	AAIPrisonGuardBotZapper Zapper;
	UBasicAITargetingComponent TargetComp;
	UPrisonGuardBotSettings Settings;
	FQuat CachedActorRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Zapper = Cast<AAIPrisonGuardBotZapper>(HazeOwningActor);
		if (Zapper == nullptr)
			return;

		TargetComp = UBasicAITargetingComponent::Get(HazeOwningActor);
		Settings = UPrisonGuardBotSettings::GetSettings(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Zapper == nullptr)
			return;

		const bool bIsControlledByPlayer = Zapper.bIsControlledByPlayer;

		const FName RequestedAnim = Zapper.AnimComp.GetFeatureTag();
		bIsShooting = (RequestedAnim == PrisonZapperAnimTags::Shooting);

		if (RequestedAnim == PrisonZapperAnimTags::HitReaction)
			HitReactionAlpha = Zapper.bIsControlledByPlayer ? 0.5 : 1;
		else
			HitReactionAlpha = 0;

		AHazePlayerCharacter Player = Game::Mio;
		FVector ShootingTargetLocation;
		if (bIsShooting)
			ShootingTargetLocation = Zapper.ShootingTargetLocation;
		else if (bIsControlledByPlayer)
			ShootingTargetLocation = Player.ViewLocation + (Player.ViewRotation.ForwardVector * 5000.0);
		else if (TargetComp.IsValidTarget(Player) && Player.ActorCenterLocation.IsWithinDist(HazeOwningActor.ActorLocation, Settings.ZapAttackRange + 500.0))
			ShootingTargetLocation = Player.ActorCenterLocation;
		else
			ShootingTargetLocation = HazeOwningActor.ActorLocation + HazeOwningActor.ActorForwardVector * 5000.0;

		const FVector LocalVelocity = Zapper.GetActorLocalVelocity();

		if (bIsControlledByPlayer)
		{
			BlendspaceValueX = Math::Clamp(LocalVelocity.Size() / 600, 0.0, 1.0);

			const float BankingValue = Math::Clamp(CalculateAnimationBankingValue(Zapper, CachedActorRotation, DeltaTime, 100), -1.0, 1.0);
			const auto MoveComp = UPlayerMovementComponent::Get(Player);
			if (MoveComp != nullptr)
			{
				FVector Input = MoveComp.SyncedLocalSpaceMovementInputForAnimationOnly;

				const FRotator TargetRotationBanking = FRotator(0, 0, BankingValue * 15);

				FRotator TargetRotationMovement = Input.Size() > SMALL_NUMBER ?
													  FRotator(-Input.X * 15, 0, Input.Y * 10) :
													  FRotator::ZeroRotator;

				BankingSpring.SpringTo(TargetRotationMovement + TargetRotationBanking, 20, 0.3, DeltaTime);
			}
		}
		else
		{
			// AI controlled
			const float SpeedRatio = Math::Clamp(LocalVelocity.Size() / 300, 0.0, 1.0);
			BlendspaceValueX = SpeedRatio;

			FVector Direction = LocalVelocity.GetSafeNormal();

			const FRotator TargetRotationBanking = FRotator(-Direction.X * 15 * SpeedRatio, 0, Direction.Y * 20 * SpeedRatio);

			BankingSpring.SpringTo(TargetRotationBanking, 20, 0.05, DeltaTime);
		}

		// Gun rotation
		FRotator Rotation = FRotator::MakeFromXZ(
			ShootingTargetLocation - (HazeOwningActor.ActorLocation - FVector(0, 0, 70)),
			HazeOwningActor.ActorUpVector);

		GunRotation.Pitch = Math::Clamp(
			Math::FInterpTo(GunRotation.Pitch,
							Rotation.Pitch - (BankingSpring.Value.Pitch * 0.6),
							DeltaTime,
							5),
			-85,
			40);
	}
}