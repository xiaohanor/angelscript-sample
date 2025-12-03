class UWandCastCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	
	UWandPlayerComponent UserComp;
	UPlayerAimingComponent AimComp;
	AActor TargetActor = nullptr;

	bool bSpellCast = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UWandPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.PlayerData.Player == nullptr)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= UserComp.PlayerData.CastTime + 0.2)
			return true;

		if(UserComp.PlayerData.Wand == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bSpellCast = false;
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), UserComp.CastSpellAnim, UserComp.BoneFilter, BlendOutTime = 0.4);

		if(AimComp.IsAiming(UserComp))
		{
			auto AimTarget = AimComp.GetAimingTarget(UserComp).AutoAimTarget;

			if (AimTarget != nullptr)
			{
				TargetActor = AimTarget.Owner;
			}
		}

		UserComp.PlayerData.bIsCasting = true;
		UserComp.PlayerData.Wand.StartCasting();

		if(UserComp.Crosshair != nullptr)
			UserComp.Crosshair.BP_OnShoot();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.PlayerData.bIsCasting = false;
		TargetActor = nullptr;

		if(AimComp.GetCrosshairWidget(UserComp) != nullptr)
			AimComp.GetCrosshairWidget(UserComp).bDisableLerpCrosshairPos = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bSpellCast)
			return;

		if (ActiveDuration >= UserComp.PlayerData.CastTime)
		{
			Player.PlayForceFeedback(UserComp.ForceFeedback, false, false, this);
			CastSpell();
		}
	}

	FHitResult Trace()
	{
		FHazeTraceDebugSettings Debug;
		Debug.Thickness = 5.0;
		Debug.Duration = 1;
		Debug.TraceColor = FLinearColor::Green;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);

		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Player);

		FVector ToCamOffset = (Player.ViewLocation - Player.ActorLocation);
		ToCamOffset = ToCamOffset.ConstrainToPlane(Player.ViewRotation.ForwardVector);
		FVector Start = Player.ActorLocation + ToCamOffset;
		FVector End = Start + Player.ViewRotation.ForwardVector * 1500.0;
		FHitResultArray Hits = TraceSettings.QueryTraceMulti(Start, End);
		FHitResult HitResult;
		TraceSettings.DebugDraw(Debug);

		for(auto Hit : Hits)
		{
			if(UPolymorphResponseComponent::Get(Hit.Actor.AttachmentRootActor) != nullptr)
			{
				HitResult = Hit;
				break;
			}
		}


		if(!HitResult.bBlockingHit)
		{
			HitResult.Location = End;
		}

		return HitResult;
	}

	FHitResult TraceForStatic()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);

		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Player);

		FVector ToCamOffset = (Player.ViewLocation - Player.ActorLocation);
		ToCamOffset = ToCamOffset.ConstrainToPlane(Player.ViewRotation.ForwardVector);
		FVector Start = Player.ActorLocation + ToCamOffset;
		FVector End = Start + Player.ViewRotation.ForwardVector * 1500.0;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		return Hit;
	}

	void CastSpell()
	{
		if(UserComp.PlayerData.Wand == nullptr)
			return;
		
		bSpellCast = true;
		FVector TargetLocation;

		if(TargetActor == nullptr)
		{
			FHitResult Hit = Trace();

			if (Hit.bBlockingHit)
			{
				if(TargetActor == nullptr)
				{
					if(UPolymorphResponseComponent::Get(Hit.Actor) != nullptr)
					{
						bool bSuccess = true;
						TArray<USceneComponent> Children;
						Hit.Component.GetChildrenComponents(false, Children);

						for(auto Child : Children)
						{
							if(Cast<UMoonMarketPolymorphBlockerComponent>(Child) != nullptr)
							{
								bSuccess = false;
								break;
							}
						}

						if(bSuccess)
							TargetActor = Hit.Actor.AttachmentRootActor;
					}
					else
					{
						TargetActor = Hit.Actor.AttachmentRootActor;
					}
				}
			}
			else Hit = TraceForStatic();

			if(Hit.bBlockingHit)
				TargetLocation = Hit.Location;
			else
			{
				FVector ToCamOffset = (Player.ViewLocation - Player.ActorLocation);
				ToCamOffset = ToCamOffset.ConstrainToPlane(Player.ViewRotation.ForwardVector);
				FVector Start = Player.ActorLocation + ToCamOffset;
				FVector End = Start + Player.ViewRotation.ForwardVector * 1500.0;
				TargetLocation = End;
			}
		}
		else
		{
			TargetLocation = AimComp.GetAimingTarget(UserComp).AutoAimTargetPoint;
		}

		if(Math::IsNearlyZero(TargetLocation.Size()))
		{
			if(TargetActor != nullptr)
				TargetLocation = TargetActor.ActorLocation;
			else
			{
				FVector ToCamOffset = (Player.ViewLocation - Player.ActorLocation);
				ToCamOffset = ToCamOffset.ConstrainToPlane(Player.ViewRotation.ForwardVector);
				FVector Start = Player.ActorLocation + ToCamOffset;
				FVector End = Start + Player.ViewRotation.ForwardVector * 1500.0;
				TargetLocation = End;
			}
		}

		UserComp.TargetActor = TargetActor;
		FSpellHitData SpellData = FSpellHitData(TargetActor, TargetLocation);
		UserComp.PlayerData.Wand.FinishCasting(SpellData);
	}
};