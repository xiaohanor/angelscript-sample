class UIslandRedBlueStickyGrenadeDetonateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 75;

	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;
	UIslandSidescrollerComponent SidescrollerComp;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UIslandRedBlueStickyGrenadeSettings Settings;
	UIslandRedBlueWeaponSettings WeaponSettings;

	bool bHasEverExploded = false;
	bool bDetonated = false;
	float TimeOfDetonated = -100.0;

	const float AnimationAnticipationDelay = 0.05;
	const float AnimationTotalDuration = 0.7;
	const float BlockWeaponDuration = 0.4;

	bool bShouldDoAnimation = false;
	float MaxRadius = 0.0;
	bool bAnimationRunning = false;
	bool bWeaponsBlocked = false;
	bool bHeldWeapons = false;

	FVector RelativeDetonateLocation;
	USceneComponent DetonateAttachment;

	TArray<UIslandRedBlueStickyGrenadeResponseComponent> AffectedResponseComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(Player);
		WeaponSettings = UIslandRedBlueWeaponSettings::GetSettings(Player);
		IslandRedBlueStickyGrenade::AutoDetonate.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		WeaponUserComp.WeaponAnimData.bDetonatingRightGrenade = false;
		WeaponUserComp.WeaponAnimData.bDetonatingLeftGrenade = false;

		if(bHasEverExploded && Settings.bDebugGrenadeExplosionRadius && GrenadeUserComp.Grenade.IsActorDisabled())
		{
			float TimeSinceExplosion = Time::GetGameTimeSince(TimeOfDetonated);
			float TimeAlpha = TimeSinceExplosion / Settings.GrenadeExplosionDuration;
			float CurrentRadius = Settings.GrenadeExplosionCurve.GetFloatValue(TimeAlpha) * Settings.GrenadeExplosionRadius;

			if(CurrentRadius != 0.0)
			{
				FLinearColor Col = IslandRedBlueWeapon::IsPlayerBlue(Player) ? FLinearColor::Blue : FLinearColor::Red;
				Debug::DrawDebugSolidSphere(GrenadeUserComp.Grenade.ActorLocation, CurrentRadius,FLinearColor(Col.R, Col.G, Col.B, 0.2), 0.0, 12);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandRedBlueStickyGrenadeDetonateActivatedParams& Params) const
	{
		if(!GrenadeUserComp.Grenade.IsGrenadeThrown())
			return false;

		if(!GrenadeUserComp.Grenade.IsGrenadeAttached() && (IsInSidescroller() || Time::GetGameTimeSince(GrenadeUserComp.LastGrenadeThrow) < Settings.GrenadeDetonateCooldown))
			return false;

		if(GrenadeUserComp.Grenade.bExternallyRequestedShouldDetonate)
			return true;

		if(!IslandRedBlueStickyGrenade::AutoDetonate.IsEnabled())
		{
			if(!WasDetonateActionStarted())
				return false;
		}

		Params.bShouldTriggerAnimation = true;
		Params.ResponseComponents = GrenadeUserComp.Grenade.GetAffectedResponseComponents();
		Params.DetonateAttachment = GrenadeUserComp.Grenade.RootComponent.AttachParent;
		if (IsValid(Params.DetonateAttachment) && Params.DetonateAttachment.IsObjectNetworked())
		{
			Params.RelativeDetonateLocation = GrenadeUserComp.Grenade.RootComponent.RelativeLocation;
		}
		else
		{
			Params.DetonateAttachment = nullptr;
			Params.RelativeDetonateLocation = GrenadeUserComp.Grenade.RootComponent.WorldLocation;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bShouldDoAnimation && ActiveDuration < AnimationTotalDuration)
			return false;

		if(!bDetonated)
			return false;

		if(Time::GetGameTimeSince(TimeOfDetonated) < Settings.GrenadeExplosionDuration)
			return false;

		return true;
	}

	bool WasDetonateActionStarted() const
	{
		if(WasActionStarted(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandRedBlueStickyGrenadeDetonateActivatedParams Params)
	{
		AffectedResponseComps = Params.ResponseComponents;
		RelativeDetonateLocation = Params.RelativeDetonateLocation;
		DetonateAttachment = Params.DetonateAttachment;

		Player.PlayForceFeedback(GrenadeUserComp.DetonateForceFeedback, false, true, this);
		for (AHazePlayerCharacter Current : Game::GetPlayers())
		{
			if(Current.IsPendingFullscreen())
			{
				Current.PlayCameraShake(GrenadeUserComp.FullscreenDetonateCamShake, this);
			}
			else if(!Current.IsPendingFullscreen() && !Current.OtherPlayer.IsPendingFullscreen())
			{
				Current.PlayWorldCameraShake(GrenadeUserComp.DetonateCamShake, this, GrenadeUserComp.Grenade.ActorLocation, Settings.GrenadeExplosionRadius, Settings.GrenadeExplosionRadius * 2.0, 1.0, 0.6);
			}
		}

		ForceFeedback::PlayWorldForceFeedback(GrenadeUserComp.DetonateWorldForceFeedback, GrenadeUserComp.Grenade.ActorLocation, true, this, Settings.GrenadeExplosionRadius, Settings.GrenadeExplosionRadius);

		bDetonated = false;
		MaxRadius = 0.0;
		bShouldDoAnimation = Params.bShouldTriggerAnimation;
		GrenadeUserComp.Grenade.bExternallyRequestedShouldDetonate = false;
		
		bHeldWeapons = WeaponUserComp.HasWeaponsInHands();
		WeaponUserComp.WeaponAnimData.bDetonatingHeldWeapons = bHeldWeapons;

		if(bShouldDoAnimation)
		{
			InitializeAnimation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		float Min = 0.0, Max = 0.0;
		Settings.GrenadeExplosionCurve.GetValueRange(Min, Max);

		float ActualMax = Max * Settings.GrenadeExplosionRadius;
		if(ActualMax > MaxRadius)
			TriggerResponseComponents(ActualMax);

		WeaponUserComp.WeaponAnimData.ClearOverriddenAimDirection(this);
		UnblockWeapons();
		GrenadeUserComp.Grenade.EndDetonation_Internal();
		AffectedResponseComps.Reset();

		if(bShouldDoAnimation && bAnimationRunning)
			ResetAnimation();

		TEMPORAL_LOG(this).Value("Detonated", bDetonated);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHeldWeapons && bAnimationRunning && !WeaponUserComp.WantsToFireWeapon() && (SidescrollerComp == nullptr || !SidescrollerComp.IsInSidescrollerMode()))
		{
			WeaponUserComp.WeaponAnimData.ApplyOverriddenAimDirection(Player.ActorForwardVector, this, 0.0);
		}
		else
		{
			WeaponUserComp.WeaponAnimData.ClearOverriddenAimDirection(this);
		}

		if(!bShouldDoAnimation)
		{
			DetonateTick();
			return;
		}

		if(bAnimationRunning && ActiveDuration > AnimationTotalDuration)
			ResetAnimation();

		if(bWeaponsBlocked && ActiveDuration > BlockWeaponDuration)
			UnblockWeapons();

		if(Player.Mesh.CanRequestOverrideFeature() && bAnimationRunning)
		{
			//WeaponUserComp.WeaponAnimData.AimDirection = (GrenadeUserComp.Grenade.ActorLocation - Player.ActorCenterLocation).GetSafeNormal();

			bool bCanRequestAnimation = true;
			if(IsInContextualMoveThatShouldBlockAnimation())
				bCanRequestAnimation = false;
			else if(ActiveDuration > AnimationTotalDuration - WeaponSettings.BlendArmsDownToThighsDuration)
				bCanRequestAnimation = false;
			
			if(bCanRequestAnimation)
			{
				if(!WeaponUserComp.IsOverrideFeatureBlocked())
					Player.Mesh.RequestOverrideFeature(IsInSidescroller() ? n"CopsGunAimOverride2D" : n"CopsGunAimOverride", this);
				WeaponUserComp.WeaponAnimData.LastFrameWeAimed = Time::FrameNumber;
			}
		}

		if(ActiveDuration < AnimationAnticipationDelay)
			return;

		if(!bDetonated || Time::GetGameTimeSince(TimeOfDetonated) < Settings.GrenadeExplosionDuration)
			DetonateTick();
	}

	bool IsInSidescroller() const
	{
		return SidescrollerComp != nullptr && SidescrollerComp.IsInSidescrollerMode();
	}

	void DetonateTick()
	{
		if(!bDetonated)
		{
			bDetonated = true;
			bHasEverExploded = true;
			TimeOfDetonated = Time::GetGameTimeSeconds();
			GrenadeUserComp.Grenade.DetachGrenade();
			GrenadeUserComp.Grenade.StartDetonate_Internal();
			TEMPORAL_LOG(this).Value("StartDetonate", true);
		}

		float CurrentTimeAlpha = Time::GetGameTimeSince(TimeOfDetonated) / Settings.GrenadeExplosionDuration;
		float CurrentRadius = Settings.GrenadeExplosionCurve.GetFloatValue(CurrentTimeAlpha) * Settings.GrenadeExplosionRadius;
		MaxRadius = Math::Max(MaxRadius, CurrentRadius);

		if(CurrentRadius > 0.0)
		{
			TriggerResponseComponents(CurrentRadius);
		}

		TEMPORAL_LOG(this).Value("DetonateTick", true);
	}

	void InitializeAnimation()
	{
		WeaponUserComp.AttachWeaponToHand(this);
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
		if(GrenadeUserComp.bCurrentGrenadeThrowingHandIsRight)
			WeaponUserComp.WeaponAnimData.bDetonatingRightGrenade = true;
		else
			WeaponUserComp.WeaponAnimData.bDetonatingLeftGrenade = true;

		bAnimationRunning = true;
		bWeaponsBlocked = true;
	}

	void TriggerResponseComponents(float CurrentRadius)
	{
		FVector WorldDetonateLocation;
		if (IsValid(DetonateAttachment))
			WorldDetonateLocation = DetonateAttachment.WorldTransform.TransformPosition(RelativeDetonateLocation);
		else
			WorldDetonateLocation = RelativeDetonateLocation;

		GrenadeUserComp.Grenade.TriggerResponseComponents_Internal(AffectedResponseComps, WorldDetonateLocation, CurrentRadius);
	}

	void ResetAnimation()
	{
		WeaponUserComp.AttachWeaponToThigh(this);
		WeaponUserComp.WeaponAnimData.bDetonatingRightGrenade = false;
		WeaponUserComp.WeaponAnimData.bDetonatingLeftGrenade = false;
		bAnimationRunning = false;
		UnblockWeapons();
	}

	void UnblockWeapons()
	{
		if(!bWeaponsBlocked)
			return;

		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
		bWeaponsBlocked = false;
	}

	bool IsInContextualMoveThatShouldBlockAnimation() const
	{
		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::WallScramble))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Grapple))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::AirJump))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Dash))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Ladder))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::PoleClimb))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Swimming))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::DashRollState))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::RollDashJumpStart))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::HighSpeedLanding))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::ApexDive))
			return true;

		if(Player.IsCapabilityTagBlocked(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation))
			return true;
		
		return false;
	}
}

struct FIslandRedBlueStickyGrenadeDetonateActivatedParams
{
	bool bShouldTriggerAnimation = false;
	FVector RelativeDetonateLocation;
	USceneComponent DetonateAttachment;
	TArray<UIslandRedBlueStickyGrenadeResponseComponent> ResponseComponents;
}