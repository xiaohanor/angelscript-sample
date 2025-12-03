class UIslandOverseerReturnGrenadeFireCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	bool bRobertDebug = false;

	UIslandOverseerSettings Settings;
	AIslandOverseerReturnGrenade ReturnGrenade;
	bool bReverse;
	TArray<FIslandOverseerReturnGrenadeFireCapabilityBarSection> BarSections;
	float OperationalTimer;

	float TelegraphDuration = 1;
	bool Telegraphed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ReturnGrenade = Cast<AIslandOverseerReturnGrenade>(Owner);
		ReturnGrenade.FireBase.SetVisibility(false, true);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bRobertDebug)
			return true;

		if(!ReturnGrenade.bOperational)	
			return false;
		if(ReturnGrenade.bReturned)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bRobertDebug)
			return false;

		if(!ReturnGrenade.bOperational)
			return true;
		if(ReturnGrenade.bReturned)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(Settings == nullptr)
		{
			if(ReturnGrenade.Launcher == nullptr)
				Settings = UIslandOverseerSettings::GetSettings(ReturnGrenade);
			else
				Settings = UIslandOverseerSettings::GetSettings(ReturnGrenade.Launcher);
		}
		ReturnGrenade.FireBase.SetVisibility(true, true);
		bReverse = Math::RandBool();
		OperationalTimer = 0;

		Telegraphed = false;
		ReturnGrenade.FireTelegraphFx.Activate();

		ReturnGrenade.FireBase.RelativeRotation = FRotator(0, Math::RandRange(0, 360), 0);
		SetupSections();

		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnLanded(ReturnGrenade);
	}

	private void SetupSections()
	{
		TArray<USceneComponent> Sections;
		ReturnGrenade.FireBar.GetChildrenComponents(false, Sections);
		float Alpha = 0;
		for(USceneComponent Section : Sections)
		{
			FVector StartOffset = ReturnGrenade.ActorRightVector * ReturnGrenade.DamageBarStartOffset;
			float Distance = ReturnGrenade.DamageBarDistance;
			FVector DestinationVector = bReverse ? -ReturnGrenade.ActorForwardVector : ReturnGrenade.ActorForwardVector;
			Section.RelativeLocation = BezierCurve::GetLocation_1CP(StartOffset, StartOffset + ReturnGrenade.ActorRightVector * Distance, StartOffset + ReturnGrenade.ActorRightVector * Distance + DestinationVector * Distance, Alpha);
			Section.RelativeLocation = FVector(Section.RelativeLocation.X, Section.RelativeLocation.Y, -Alpha * ReturnGrenade.DamageBarSpacing);
			Section.RelativeScale3D = FVector::OneVector * (1 - ReturnGrenade.DamageBarScaling * Alpha);
			Alpha += float(1) / Sections.Num();

			FIslandOverseerReturnGrenadeFireCapabilityBarSection Data;
			Data.Section = Section;
			Data.OriginalRelativeLocation = Section.RelativeLocation;
			BarSections.Add(Data);
			Data.Section.RelativeLocation = FVector::ZeroVector;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ReturnGrenade.FireBase.SetVisibility(false, true);
		for(FIslandOverseerReturnGrenadeFireCapabilityBarSection& Section : BarSections)
		{
			Section.Section.RelativeLocation = FVector::ZeroVector;
			Section.AccLocation.SnapTo(FVector::ZeroVector);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!ReturnGrenade.bOperational && bRobertDebug == false)
			return;

		if(ActiveDuration < TelegraphDuration)
		{

			return;
		}

		if(!Telegraphed)
		{
			Telegraphed = true;
			ReturnGrenade.FireTelegraphFx.Deactivate();
		}

		OperationalTimer += DeltaTime;

		for(FIslandOverseerReturnGrenadeFireCapabilityBarSection& Section : BarSections)
		{
			Section.AccLocation.AccelerateTo(Section.OriginalRelativeLocation, 1, DeltaTime);
			Section.Section.SetRelativeLocation(Section.AccLocation.Value);
			Section.Section.AddLocalRotation(FRotator(0, 150, 0) * DeltaTime);
		}

		if(OperationalTimer < 1)
			return;

		FRotator Rotation = FRotator(0, 30, 0);
		if(bReverse)
			Rotation *= -1;
		ReturnGrenade.FireBase.RelativeRotation += Rotation * DeltaTime;

		for(int i = 0; i < BarSections.Num() - 7; i++)
		{
			FIslandOverseerReturnGrenadeFireCapabilityBarSection Section = BarSections[i];
			for(AHazePlayerCharacter Player : Game::Players)
			{
				float Radius = 70;
				if(Section.Section.WorldLocation.Distance(Player.ActorLocation) > Radius)
					continue;

				if (Player.HasControl())
				{
					Player.DealBatchedDamageOverTime(Settings.ReturnGrenadePlayerDamagePerSecond * DeltaTime, FPlayerDeathDamageParams(), ReturnGrenade.DamageEffect, ReturnGrenade.DeathEffect);
					Player.ApplyAdditiveHitReaction((Player.ActorLocation - Owner.ActorLocation).GetSafeNormal(), EPlayerAdditiveHitReactionType::Small);
					UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Player);
				}
			}
		}
	}
}

struct FIslandOverseerReturnGrenadeFireCapabilityBarSection
{
	USceneComponent Section;
	FVector OriginalRelativeLocation;
	FHazeAcceleratedVector AccLocation;
}
