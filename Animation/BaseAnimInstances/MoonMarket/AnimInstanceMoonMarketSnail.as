class UAnimInstanceMoonMarketSnail : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator NeckRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HeadRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	AMoonMarketSnail Snail;

	FVector GroundNormal;

	FRotator CachedActorRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Snail = Cast<AMoonMarketSnail>(HazeOwningActor);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);

		CachedActorRotation = HazeOwningActor.ActorRotation;

		Snail.FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnFireworkHit");
		Snail.ThunderStruckComp.OnStruckByThunder.AddUFunction(this, n"OnStruckByThunder");
	}

	UFUNCTION()
	private void OnFireworkHit(FMoonMarketFireworkImpactData Data)
	{
		NeckRotation = FRotator::ZeroRotator;
		HeadRotation = FRotator::ZeroRotator;
	}

	UFUNCTION()
	private void OnStruckByThunder(FMoonMarketThunderStruckData Data)
	{
		NeckRotation = FRotator::ZeroRotator;
		HeadRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Snail == nullptr)
			return;

		BlendspaceValues.Y = Snail.MoveComp.Velocity.Size();

		if(BlendspaceValues.Y > 5)
		{
			if(!bIsMoving)
			{
				UMoonMarketSnailEventHandler::Trigger_OnStartMoving(Snail);
			}
		}
		else
		{
			if(bIsMoving)
			{
				UMoonMarketSnailEventHandler::Trigger_OnStopMoving(Snail);
			}
		}

		bIsMoving = BlendspaceValues.Y > 5;
		if (bIsMoving)
		{
			SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 5);

			auto DeltaRotation = (CachedActorRotation - HazeOwningActor.ActorRotation).Normalized;
			CachedActorRotation = HazeOwningActor.ActorRotation;

			BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X,
												 -(DeltaRotation.Yaw / DeltaTime) / 40.0,
												 DeltaTime,
												 4);
		}
		else
		{
			BlendspaceValues.X = 0;
			LookAtPlayer(DeltaTime);
		}
	}

	void LookAtPlayer(float DeltaTime)
	{
		if(Snail.ThunderStruckComp.bThunderStruck)
			return;

		if(Snail.StunComponent.StunDuration > 0)
			return;

		const float LookRange = 400;
		auto ClosestPlayer = Game::GetClosestPlayer(Snail.ActorLocation);
		if(ClosestPlayer != nullptr && ClosestPlayer == Snail.InteractingPlayer)
			ClosestPlayer = ClosestPlayer.OtherPlayer;

		if(ClosestPlayer != nullptr && ClosestPlayer.GetSquaredDistanceTo(Snail) < LookRange * LookRange)
		{
			FVector PlayerRelativeLoc = Snail.ActorTransform.InverseTransformPosition(ClosestPlayer.ActorLocation);
			float LookSpeed = 2;
			FRotator TargetRotation = PlayerRelativeLoc.Rotation();
			
			const float MaxNeckYaw = 50;

			//Head
			float TargetHeadYaw = 0;
			if(Math::Abs(TargetRotation.Yaw) > MaxNeckYaw)
			{
				const float MaxHeadYaw = 30;
				TargetHeadYaw = TargetRotation.Yaw - (MaxNeckYaw * Math::Sign(TargetRotation.Yaw));
				TargetHeadYaw = Math::ClampAngle(TargetHeadYaw, -MaxHeadYaw, MaxHeadYaw);
			}
			HeadRotation = Math::RInterpTo(HeadRotation, FRotator(0, TargetHeadYaw, 0), DeltaTime, LookSpeed);

			//Neck
			TargetRotation.Yaw = Math::ClampAngle(TargetRotation.Yaw, -MaxNeckYaw, MaxNeckYaw);
			TargetRotation.Pitch = Math::ClampAngle(TargetRotation.Pitch, -70, 70);
			TargetRotation.Roll = 0;
			NeckRotation = Math::RInterpTo(NeckRotation, TargetRotation, DeltaSeconds, LookSpeed);
		}
		else
		{
			const float LookBackSpeed = 1;
			HeadRotation = Math::RInterpTo(HeadRotation, FRotator::ZeroRotator, DeltaTime, LookBackSpeed);
			NeckRotation = Math::RInterpTo(NeckRotation, FRotator::ZeroRotator, DeltaSeconds, LookBackSpeed);
		}
	}
}