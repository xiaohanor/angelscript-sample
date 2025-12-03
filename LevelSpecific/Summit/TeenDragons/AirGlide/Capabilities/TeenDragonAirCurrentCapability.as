class UTeenDragonAirCurrentCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 28;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UTeenDragonAirGlideSettings AirGlideSettings;

	bool bHasTriggeredAscentStartEvent = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);

		Player.OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		Player.OnActorEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			for (ASummitAirCurrent Current : AirGlideComp.OverlappedAirCurrents)
			{
				if (!AirGlideComp.ActiveAirCurrents.Contains(Current) && Current.IsEnabled())
					AirGlideComp.ActiveAirCurrents.AddUnique(Current);

				if(!IsActive() 
				&& AirGlideComp.OverlappedAirCurrents.Contains(Current)
				&& !Current.IsEnabled())
					AirGlideComp.ActiveAirCurrents.RemoveSingleSwap(Current);
			}
		}
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Current = Cast<ASummitAirCurrent>(OtherActor);
		if (Current == nullptr)
			return;

		AirGlideComp.OverlappedAirCurrents.Add(Current);
	}

	UFUNCTION()
	private void OnEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Current = Cast<ASummitAirCurrent>(OtherActor);
		if (Current == nullptr)
			return;
		
		AirGlideComp.OverlappedAirCurrents.Remove(Current);
		
		// Dont want to remove active air currents here if active because they get removed when reached the top 
		if(!IsActive())
		{
			if (AirGlideComp.ActiveAirCurrents.Contains(Current))
				AirGlideComp.ActiveAirCurrents.Remove(Current);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		AirGlideComp.ActiveAirCurrents.Empty();
		AirGlideComp.OverlappedAirCurrents.Empty();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AirGlideComp.ActiveAirCurrents.Num() == 0)
			return false;

		if(EveryAirCurrentIsBlocked())
			return false;

		if(!AirGlideComp.bIsAirGliding)
			return false;

		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AirGlideComp.ActiveAirCurrents.Num() == 0)
			return true;

		if(EveryAirCurrentIsBlocked())
			return true;

		if(!AirGlideComp.bIsAirGliding)
			return true;

		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasTriggeredAscentStartEvent = false;
		AirGlideComp.bInAirCurrent = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
		{
			for(int i = AirGlideComp.ActiveAirCurrents.Num() - 1; i >= 0; i--)
			{
				auto Current = AirGlideComp.ActiveAirCurrents[i];
				// Have exited current
				if(!AirGlideComp.OverlappedAirCurrents.Contains(Current))
					AirGlideComp.ActiveAirCurrents.RemoveSingleSwap(Current);
				
				// Is disabled
				if(!Current.IsEnabled())
					AirGlideComp.ActiveAirCurrents.RemoveSingleSwap(Current);
			}
		}

		AirGlideComp.bInAirCurrent = false;
	}

	bool EveryAirCurrentIsBlocked() const
	{
		for(auto AirCurrent : AirGlideComp.ActiveAirCurrents)
		{
			if(AirCurrent.AirCurrentIsBlocked())
				return true;
		}
		return false;
	}
	 
	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float VerticalDelta = CalculateVerticalDelta(DeltaTime);
			AirGlideComp.SetGlideVerticalSpeed(VerticalDelta / DeltaTime);

			TEMPORAL_LOG(Player, "Air Glide").Page("Vertical Speed")
				.Status("Air current", FLinearColor::DPink)
			;

			if(!bHasTriggeredAscentStartEvent
			&& VerticalDelta > 0)
			{
				CrumbTriggerStartAscendingEvent();
				bHasTriggeredAscentStartEvent = true;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerStartAscendingEvent()
	{
		for(auto AirCurrent : AirGlideComp.ActiveAirCurrents)
		{
			USummitAirCurrentEventHandler::Trigger_OnDragonStartedAscending(AirCurrent);
			AirCurrent.OnDragonStartedAscending.Broadcast();
		}
	}

	float CalculateVerticalDelta(float DeltaTime)
	{
		// Determine how high or low we can go based on the current
		float CurrentHeight = Player.ActorLocation.Z;
		float LowestAllowedHeight = MAX_flt;
		float HighestAllowedHeight = -MAX_flt;

		for(int i = AirGlideComp.ActiveAirCurrents.Num() - 1; i >= 0; i--)
		{
			auto Current = AirGlideComp.ActiveAirCurrents[i];

			float LowerPoint = Current.CurrentBox.WorldLocation.Z - Current.CurrentBox.ScaledBoxExtent.Z;
			float UpperPoint = Current.CurrentBox.WorldLocation.Z + Current.CurrentBox.ScaledBoxExtent.Z - 50.0;

			if (LowerPoint < LowestAllowedHeight)
				LowestAllowedHeight = LowerPoint;
			if (UpperPoint > HighestAllowedHeight)
				HighestAllowedHeight = UpperPoint;
			
#if !RELEASE
			FLinearColor CurrentTempLogColor;
			if(!Current.IsEnabled())
				CurrentTempLogColor = FLinearColor::Red;
			else if(AirGlideComp.OverlappedAirCurrents.Contains(Current))
				CurrentTempLogColor = FLinearColor::Gray;
			else
				CurrentTempLogColor = FLinearColor::Green;
			TEMPORAL_LOG(Player, "Air Currents")
				.Box(f"{Current}", Current.CurrentBox.WorldLocation, Current.CurrentBox.BoxExtent, Current.CurrentBox.WorldRotation, CurrentTempLogColor, 20)
			;
#endif
			
			// Have exited current
			if(!AirGlideComp.OverlappedAirCurrents.Contains(Current)
			|| !Current.IsEnabled())
			{
				// At the top 95% of the current
				float HeightPct = (CurrentHeight - LowestAllowedHeight) / (HighestAllowedHeight - LowestAllowedHeight);
				if(HeightPct > 0.95)
					AirGlideComp.ActiveAirCurrents.RemoveSingleSwap(Current);
			}
		}

		float CurrentVerticalSpeed = AirGlideComp.GetGlideVerticalSpeed();
		if(AirGlideComp.ActiveAirCurrents.Num() == 0)
			return CurrentVerticalSpeed * DeltaTime;

		auto FirstActiveCurrent = AirGlideComp.ActiveAirCurrents[0];

		float TargetVerticalSpeed = FirstActiveCurrent.SpeedOfCurrent;
		float CurrentAcceleration = FirstActiveCurrent.AccelerationOfCurrent;
		if(CurrentVerticalSpeed < 0)
			CurrentAcceleration *= 2.0;

		if (TargetVerticalSpeed < CurrentVerticalSpeed)
			CurrentVerticalSpeed = TargetVerticalSpeed;
		else
			CurrentVerticalSpeed = Math::FInterpConstantTo(CurrentVerticalSpeed, TargetVerticalSpeed, DeltaTime, CurrentAcceleration);

		float VerticalDelta = CurrentVerticalSpeed * DeltaTime;

		// Never allow going outside the height bounds of the air current
		VerticalDelta = Math::Clamp(VerticalDelta, LowestAllowedHeight - CurrentHeight, HighestAllowedHeight - CurrentHeight);

		// Slow down as we get closer to the top
		float HeightPct = (CurrentHeight - LowestAllowedHeight) / (HighestAllowedHeight - LowestAllowedHeight);
		if (HeightPct > 0.75 && VerticalDelta > 0.0)
		{
			float MaxSpeedPct = 1.0 - ((HeightPct - 0.75) / 0.25);
			VerticalDelta = Math::Min(VerticalDelta, CurrentAcceleration * MaxSpeedPct * DeltaTime);
		}
		else if (HeightPct < 0.25 && VerticalDelta < 0.0)
		{
			float MaxSpeedPct = (HeightPct / 0.25);
			VerticalDelta = Math::Max(VerticalDelta, -CurrentAcceleration * MaxSpeedPct * DeltaTime);
		}
		return VerticalDelta;
	}
};