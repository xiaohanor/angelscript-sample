class UTundraBossWhirlwindForceResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);

	const UTundraBossWhirlwindForceComponent ForceComp;

	UBaseMovementResolver Resolver;

	FVector ForceDirection;
	float ForceStrength;

	bool SupportsResolver(const UBaseMovementResolver InResolver) const override
	{
		if(!InResolver.Owner.IsA(AHazePlayerCharacter))
			return false;

		return Super::SupportsResolver(InResolver);
	}

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UTundraBossWhirlwindForceResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		ForceDirection = Other.ForceDirection;
		ForceStrength = Other.ForceStrength;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		Resolver = InResolver;

		auto ForceResolverComp = UTundraBossWhirlwindForceResolverExtensionComponent::Get(InResolver.Owner);
		ForceComp = ForceResolverComp.ForceComp;

		auto OwningPlayer = Cast<AHazePlayerCharacter>(Resolver.Owner);
		ForceDirection = ForceComp.GetDirectionForPlayer(OwningPlayer);
		ForceStrength = ForceComp.GetForceStrengthForPlayer(OwningPlayer);
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		if(!bFirstIteration)
			return true;

		FVector ForceVelocity = ForceDirection * ForceStrength;

		FMovementDelta OriginalDelta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
		OriginalDelta = FMovementDelta(OriginalDelta.Delta + ForceVelocity * Resolver.IterationTime, OriginalDelta.Velocity + ForceVelocity);

		Resolver.IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, OriginalDelta);
		return true;
	}

	void PreApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::PreApplyResolvedData(MovementComponent);
		
		FVector ForceVelocity = ForceDirection * ForceStrength;

		FMovementDelta OriginalDelta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
		OriginalDelta = FMovementDelta(OriginalDelta.Delta - ForceVelocity * Resolver.IterationTime, OriginalDelta.Velocity - ForceVelocity);

		Resolver.IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, OriginalDelta);
	}

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		if(ForceComp == nullptr)
			return;

		FinalSectionLog.Value("ForceComp", ForceComp);
		FinalSectionLog.DirectionalArrow("ForceDirection", Resolver.Owner.ActorLocation, ForceDirection * 100.0);
		FinalSectionLog.Value("ForceStrength", ForceStrength);
	}
#endif
}

class UTundraBossWhirlwindForceResolverExtensionComponent : UActorComponent
{
	UTundraBossWhirlwindForceComponent ForceComp;
}

class UTundraBossWhirlwindForceComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float OuterRadius = 3000.0;

	UPROPERTY(EditAnywhere)
	float InnerRadius = 1500.0;

	UPROPERTY(EditAnywhere)
	float ForceStrength = 500.0;

	UPROPERTY(EditAnywhere)
	float PlayerForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float TreeGuardianForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float FairyForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float SnowMonkeyForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float OtterForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float ForceStartAccelerationDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float ForceStopAccelerationDuration = 3.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ForceCurve;
	default ForceCurve.AddDefaultKey(0.0, 0.0);
	default ForceCurve.AddDefaultKey(1.0, 1.0);

	FHazeAcceleratedFloat AcceleratedForceStrength;
	float CurrentAccelerationDuration = 0.0;
	float TargetForceStrength = 0.0;
	bool bApplyingForce = false;
	ATundraBossWhirlwindActor WhirlwindActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhirlwindActor = Cast<ATundraBossWhirlwindActor>(Owner);
		devCheck(WhirlwindActor != nullptr, "Can't place a whirlwind force component on an actor that isn't a ATundraBossWhirlwindActor");
		WhirlwindActor.OnWhirlwindStart.AddUFunction(this, n"OnWhirlwindStart");
		WhirlwindActor.OnWhirlwindStop.AddUFunction(this, n"OnWhirlwindStop");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AcceleratedForceStrength.AccelerateTo(TargetForceStrength, CurrentAccelerationDuration, DeltaTime);
		bool bForceIsRelevant = !Math::IsNearlyZero(AcceleratedForceStrength.Value);
		if(bApplyingForce != bForceIsRelevant)
		{
			bApplyingForce = bForceIsRelevant;
			if(bApplyingForce)
			{
				for(AHazePlayerCharacter Player : Game::Players)
				{
					auto ExtensionComp = UTundraBossWhirlwindForceResolverExtensionComponent::GetOrCreate(Player);
					ExtensionComp.ForceComp = this;
					Player.ApplyResolverExtension(UTundraBossWhirlwindForceResolverExtension, this);
				}
			}
			else
			{
				for(AHazePlayerCharacter Player : Game::Players)
				{
					auto ExtensionComp = UTundraBossWhirlwindForceResolverExtensionComponent::GetOrCreate(Player);
					ExtensionComp.ForceComp = nullptr;
					Player.ClearResolverExtension(UTundraBossWhirlwindForceResolverExtension, this);
				}
			}
		}

		// This doesn't work because some capabilities such as FloorMotion handles velocity a bit weirdly, so solve it with a resolver extension instead!
		// for(AHazePlayerCharacter Player : Game::Players)
		// {
		// 	float Force = GetForceStrengthForPlayer(Player);
		// 	FVector Direction = GetDirectionForPlayer(Player);
		// 	Player.SetActorHorizontalVelocity(Player.ActorHorizontalVelocity + Direction * Force * DeltaTime);
		// }
	}

	float GetForceStrengthForPlayer(AHazePlayerCharacter Player) const
	{
		float Distance = Player.ActorLocation.DistXY(WorldLocation);
		float Alpha = Math::NormalizeToRange(Distance, InnerRadius, OuterRadius);
		Alpha = ForceCurve.GetFloatValue(Alpha);
		float Multiplier = 1.0;
		ETundraShapeshiftShape Shape = TundraShapeshiftingStatics::TundraGetCurrentShapeshiftShape(Player);
		switch(Shape)
		{
			case ETundraShapeshiftShape::None:
				break;
			case ETundraShapeshiftShape::Small:
				Multiplier = Player.IsZoe() ? FairyForceMultiplier : OtterForceMultiplier;
				break;
			case ETundraShapeshiftShape::Player:
				Multiplier = PlayerForceMultiplier;
				break;
			case ETundraShapeshiftShape::Big:
				Multiplier = Player.IsZoe() ? TreeGuardianForceMultiplier : SnowMonkeyForceMultiplier;
				break;
		}
		return Alpha * AcceleratedForceStrength.Value * Multiplier;
	}

	FVector GetDirectionForPlayer(AHazePlayerCharacter Player) const
	{
		return (WorldLocation - Player.ActorLocation).GetSafeNormal2D();
	}

	UFUNCTION()
	private void OnWhirlwindStart(float Delay)
	{
		if(Delay > 0.0)
		{
			Timer::SetTimer(this, n"OnWhirlwindStartInternal", Delay * 0.5);
		}
		else
		{
			OnWhirlwindStartInternal();
		}
	}

	UFUNCTION()
	private void OnWhirlwindStartInternal()
	{
		TargetForceStrength = ForceStrength;
		CurrentAccelerationDuration = ForceStartAccelerationDuration;
	}

	UFUNCTION()
	private void OnWhirlwindStop()
	{
		TargetForceStrength = 0.0;
		CurrentAccelerationDuration = ForceStopAccelerationDuration;
	}
}

class UTundraBossWhirlwindForceComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraBossWhirlwindForceComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ForceComp = Cast<UTundraBossWhirlwindForceComponent>(Component);
		DrawCircle(ForceComp.WorldLocation, ForceComp.OuterRadius, FLinearColor::Red, 5.0);
		DrawCircle(ForceComp.WorldLocation, ForceComp.InnerRadius, FLinearColor::Green, 5.0);
	}
}