class UIslandRedBlueStickyGrenadeThrowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);

	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UIslandSidescrollerComponent SidescrollerComp;
	UIslandRedBlueStickyGrenadeSettings Settings;
	UIslandRedBlueWeaponSettings WeaponSettings;

	bool bWeaponsBlocked = false;

	const float AnimationAnticipationDelay = 0.07;
	const float AnimationTotalDuration = 0.6;
	const float BlockWeaponsDuration = 0.4;

	bool bGrenadeThrown = false;
	bool bWeaponsAttachedToHands = false;
	float CurrentForceFeedbackStrength = 0.0;
	bool bPlayForceFeedback = true;

	USceneComponent GrenadeTargetComponent;
	FVector GrenadeTargetLocalPoint;
	FHitResult TargetHit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
		Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(Player);
		WeaponSettings = UIslandRedBlueWeaponSettings::GetSettings(Player);
		IslandRedBlueStickyGrenade::AutoThrow.MakeVisible();
		IslandRedBlueStickyGrenade::MendForceFieldsOnThrow.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Settings.bDebugGrenadeMaxThrowDistance && AimComp.IsAiming(WeaponUserComp))
		{
			FAimingResult AimTarget = AimComp.GetAimingTarget(WeaponUserComp);
			FLinearColor Color = IslandRedBlueWeapon::IsPlayerBlue(Player) ? FLinearColor::Blue : FLinearColor::Red;
			Debug::DrawDebugSphere(AimTarget.AimOrigin, Settings.MaxThrowDistance, 12, Color, 10.0);
			Debug::DrawDebugString(AimTarget.AimOrigin + FVector::ForwardVector * Settings.MaxThrowDistance, "Max Grenade Throw Distance", Color, 0.0, 1.0);
			Debug::DrawDebugString(AimTarget.AimOrigin + FVector::BackwardVector * Settings.MaxThrowDistance, "Max Grenade Throw Distance", Color, 0.0, 1.0);
			Debug::DrawDebugString(AimTarget.AimOrigin + FVector::RightVector * Settings.MaxThrowDistance, "Max Grenade Throw Distance", Color, 0.0, 1.0);
			Debug::DrawDebugString(AimTarget.AimOrigin + FVector::LeftVector * Settings.MaxThrowDistance, "Max Grenade Throw Distance", Color, 0.0, 1.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandRedBlueStickyGrenadeThrowActivatedParams& Params) const
	{
		if(!AimComp.IsAiming(WeaponUserComp))
			return false;

		if(!IslandRedBlueStickyGrenade::AutoThrow.IsEnabled())
		{
			if(!WasActionStarted(ActionNames::SecondaryLevelAbility))
				return false;
		}

		if(GrenadeUserComp.IsGrenadeThrowingBlocked())
			return false;

		if(GrenadeUserComp.Grenade.IsGrenadeThrown())
			return false;

		if(Time::GetGameTimeSince(GrenadeUserComp.LastGrenadeThrow) < Settings.GrenadeThrowCooldown)
			return false;

		if(IsInContextualMoveThatShouldBlock())
			return false;

		Params.Targetable = Cast<UIslandRedBlueTargetableComponent>(PlayerTargetablesComp.GetPrimaryTarget(
			UIslandRedBlueTargetableComponent));
		if(Params.Targetable == nullptr || Params.Targetable.bTargetWithGrenade)
			Params.AimTarget = AimComp.GetAimingTarget(GrenadeUserComp);
		else
			Params.AimTarget = AimComp.GetAimingTarget(WeaponUserComp);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bGrenadeThrown)
			return false;

		if(!GrenadeUserComp.Grenade.IsGrenadeThrown())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandRedBlueStickyGrenadeThrowActivatedParams Params)
	{
#if TEST
		if(IslandRedBlueStickyGrenade::MendForceFieldsOnThrow.IsEnabled())
		{
			TListedActors<AIslandRedBlueForceField> ListedForceFields;
			for(AIslandRedBlueForceField ForceField : ListedForceFields.Array)
				ForceField.MendAllHoles();
		}
#endif
		GrenadeUserComp.AddGrenadeIndicatorLitInstigator(this);

		CurrentForceFeedbackStrength = Settings.ThrowForceFeedbackStartStrength;
		bPlayForceFeedback = true;

		WeaponUserComp.AttachWeaponToHand(this);
		bWeaponsAttachedToHands = true;
		WeaponUserComp.AddBlockCameraAssistanceInstigator(this);
		GrenadeUserComp.DetermineGrenadeThrowingHand();

		bGrenadeThrown = false;

		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
		bWeaponsBlocked = true;

		FVector GrenadeTarget = Params.AimTarget.AimOrigin + Params.AimTarget.AimDirection * Settings.MaxThrowDistance;

		if(Params.AimTarget.AutoAimTarget != nullptr)
		{
			GrenadeTargetComponent = Params.AimTarget.AutoAimTarget;
			GrenadeTarget = Params.AimTarget.AutoAimTargetPoint;
			TargetHit = FHitResult();
		}
		else
		{
			auto HitResult = QueryGrenadeImpact(Params.AimTarget);
			TargetHit = HitResult;
			if(HitResult.bBlockingHit)
			{
				GrenadeTargetComponent = HitResult.Component;
				GrenadeTarget = HitResult.ImpactPoint;
			}
		}

		if(GrenadeTargetComponent != nullptr)
		{
			GrenadeTargetLocalPoint = GrenadeTargetComponent.WorldTransform.InverseTransformPosition(GrenadeTarget);
		}
		else
		{
			GrenadeTargetLocalPoint = GrenadeTarget;
		}

		AIslandRedBlueWeapon Weapon = WeaponUserComp.GetWeapon(GrenadeUserComp.bCurrentGrenadeThrowingHandIsRight ? EIslandRedBlueWeaponHandType::Right : EIslandRedBlueWeaponHandType::Left);

		FIslandRedBlueStickyGrenadeOnThrowParams EffectParams;
		EffectParams.GrenadeOwner = Player;
		EffectParams.GrenadeLocation = GrenadeUserComp.Grenade.ActorLocation;

		UIslandRedBlueWeaponEffectHandler::Trigger_OnShootGrenade(Weapon, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrenadeUserComp.RemoveGrenadeIndicatorLitInstigator(this);
		GrenadeTargetComponent = nullptr;

		if(bWeaponsBlocked)
		{
			WeaponUserComp.RemoveBlockCameraAssistanceInstigator(this);
			Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
			bWeaponsBlocked = false;
		}

		if(bWeaponsAttachedToHands)
		{
			WeaponUserComp.AttachWeaponToThigh(this);
			bWeaponsAttachedToHands = false;
		}

		// If this capability was blocked we want to despawn the grenade.
		if(GrenadeUserComp.Grenade.IsGrenadeThrown())
		{
			GrenadeUserComp.Grenade.ResetGrenade();
		}

		TEMPORAL_LOG(this).Value("Thrown", bGrenadeThrown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bPlayForceFeedback && (GrenadeUserComp.Grenade.IsGrenadeAttached() || (bGrenadeThrown && GrenadeUserComp.Grenade.IsActorDisabled())))
		{
			bPlayForceFeedback = false;
		}

		if(bPlayForceFeedback)
		{
			CurrentForceFeedbackStrength += Settings.ThrowForceFeedbackStrengthIncreaseSpeed * DeltaTime;
			CurrentForceFeedbackStrength = Math::Min(CurrentForceFeedbackStrength, Settings.ThrowForceFeedbackMaxStrength);

			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.LeftTrigger = CurrentForceFeedbackStrength;
			ForceFeedback.RightMotor = CurrentForceFeedbackStrength;
			Player.SetFrameForceFeedback(ForceFeedback);
		}

		if(ActiveDuration == 0.0)
		{
			if(GrenadeUserComp.bCurrentGrenadeThrowingHandIsRight)
				WeaponUserComp.WeaponAnimData.bShotGrenadeThisTickRight = true;
			else
				WeaponUserComp.WeaponAnimData.bShotGrenadeThisTickLeft = true;
		}
		else
		{
			WeaponUserComp.WeaponAnimData.bShotGrenadeThisTickRight = false;
			WeaponUserComp.WeaponAnimData.bShotGrenadeThisTickLeft = false;
		}

		float TimeSinceThrow = Time::GetGameTimeSince(GrenadeUserComp.LastGrenadeThrow);
		if(Player.Mesh.CanRequestOverrideFeature() && (!bGrenadeThrown || TimeSinceThrow < (AnimationTotalDuration - AnimationAnticipationDelay)))
		{
			bool bCanRequestAnimation = true;
			if(IsInContextualMoveThatShouldBlock())
				bCanRequestAnimation = false;
			else if(!IsActioning(ActionNames::PrimaryLevelAbility) && !WeaponUserComp.IsAiming() && bGrenadeThrown && TimeSinceThrow > AnimationTotalDuration - AnimationAnticipationDelay - WeaponSettings.BlendArmsDownToThighsDuration)
				bCanRequestAnimation = false;
			
			if(bCanRequestAnimation)
			{
				if(!WeaponUserComp.IsOverrideFeatureBlocked())
					Player.Mesh.RequestOverrideFeature((SidescrollerComp != nullptr && SidescrollerComp.IsInSidescrollerMode()) ? n"CopsGunAimOverride2D" : n"CopsGunAimOverride", this);
				WeaponUserComp.WeaponAnimData.LastFrameWeAimed = Time::FrameNumber;
			}
		}
		else if(bWeaponsAttachedToHands)
		{
			WeaponUserComp.AttachWeaponToThigh(this);
			bWeaponsAttachedToHands = false;
		}

		if(bWeaponsBlocked && bGrenadeThrown && TimeSinceThrow > (BlockWeaponsDuration - AnimationAnticipationDelay))
		{
			WeaponUserComp.RemoveBlockCameraAssistanceInstigator(this);
			Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
			bWeaponsBlocked = false;
		}
		
		if(ActiveDuration < AnimationAnticipationDelay)
			return;

		if(!bGrenadeThrown)
			ThrowGrenade();
	}

	bool IsInContextualMoveThatShouldBlock() const
	{
		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Dash))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::AirJump))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Grapple))
			return true;

		if(Player.IsCapabilityTagBlocked(BlockedWhileIn::WallScramble))
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

	FHitResult QueryGrenadeImpact(FAimingResult AimTarget)
	{
		auto Trace = Trace::InitChannel(Settings.TraceChannel);
		Trace.IgnorePlayers();
		Trace.UseLine();
		
		FVector TraceEnd;
		if (AimTarget.AutoAimTarget != nullptr)
		{
			auto TargetComponent = Cast<UIslandRedBlueTargetableComponent>(AimTarget.AutoAimTarget);
			if(TargetComponent != nullptr)
			{
				TraceEnd = TargetComponent.GetTargetLocation(Player);
			}
			else
			{
				TraceEnd = TargetComponent.GetWorldLocation();
			}
		}
		else
		{
			TraceEnd = AimTarget.AimOrigin + (AimTarget.AimDirection * Settings.MaxThrowDistance);
		}

		FVector TraceStart = AimTarget.AimOrigin;
		TryConstrainDestinationToSpline(TraceStart, TraceEnd);
		
		auto Hits = Trace.QueryTraceMulti(TraceStart, TraceEnd);
#if !RELEASE
		TEMPORAL_LOG(this)
			.HitResults("QueryGrenadeImpact Hits", Hits, TraceStart, TraceEnd, Trace.Shape, Trace.ShapeWorldOffset)
		;
#endif

		for(auto Hit : Hits)
		{
			if(IslandRedBlueWeapon::CurrentCameraWeaponTraceHitIsValid(Player, Hit, this))
				return Hit;
		}

		auto BasicHit = FHitResult();
		BasicHit.TraceStart = TraceStart;
		BasicHit.TraceEnd = TraceEnd;
		return BasicHit;
	}

	bool TryConstrainDestinationToSpline(FVector Origin, FVector& Destination) const
	{
		if(AimComp.GetCurrentAimingConstraintType() != EAimingConstraintType2D::Spline)
			return false;

		UHazeSplineComponent Spline = AimComp.Get2DConstraintSpline();
		FQuat ClosestRotation = Spline.GetClosestSplineWorldRotationToWorldLocation(Origin);
		FVector Delta = Destination - Origin;
		Delta = Delta.ConstrainToPlane(ClosestRotation.RightVector);
		Destination = Origin + Delta;
		return true;
	}

	void ThrowGrenade()
	{
		if(!HasControl())
			return;

		CrumbThrowGrenade();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbThrowGrenade()
	{
		GrenadeUserComp.LastGrenadeThrow = Time::GetGameTimeSeconds();

		FVector GrenadeTarget, TargetVelocity;
		GetGrenadeTargetAndVelocity(GrenadeTarget, TargetVelocity);

		FName ShoulderSocketName = GrenadeUserComp.bCurrentGrenadeThrowingHandIsRight ? n"RightArm" : n"LeftArm";
		devCheck(Player.Mesh.DoesSocketExist(ShoulderSocketName), f"Tried to get socket {ShoulderSocketName}, but socket does not exist");

		FTransform OriginalTransform = GetGrenadeOriginalTransform(GrenadeTarget);
		GrenadeUserComp.Grenade.ThrowGrenade(OriginalTransform, Player.ActorVelocity, GrenadeTarget, TargetVelocity, Player.Mesh.GetSocketLocation(ShoulderSocketName), GrenadeTargetComponent, TargetHit);
		bGrenadeThrown = true;

		FIslandRedBlueStickyGrenadeOnThrowParams Params;
		Params.GrenadeOwner = Player;
		Params.GrenadeLocation = GrenadeUserComp.Grenade.ActorLocation;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnThrowGrenade(GrenadeUserComp.Grenade, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnThrowGrenade(Player, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnThrowGrenadeAudio(Game::Mio, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnThrowGrenadeAudio(Game::Zoe, Params);
	}

	void GetGrenadeTargetAndVelocity(FVector&out GrenadeTarget, FVector&out TargetVelocity) const
	{
		if(GrenadeTargetComponent != nullptr)
		{
			GrenadeTarget = GrenadeTargetComponent.WorldTransform.TransformPosition(GrenadeTargetLocalPoint);
			TargetVelocity = GrenadeTargetComponent.Owner.ActorVelocity;
		}
		else
		{
			GrenadeTarget = GrenadeTargetLocalPoint;
		}

		FTransform OriginalTransform = GetGrenadeOriginalTransform(GrenadeTarget);
		TryConstrainDestinationToSpline(OriginalTransform.Location, GrenadeTarget);
	}

	FTransform GetGrenadeOriginalTransform(FVector GrenadeTarget) const
	{
		AIslandRedBlueWeapon Weapon = WeaponUserComp.GetWeapon(GrenadeUserComp.bCurrentGrenadeThrowingHandIsRight ? EIslandRedBlueWeaponHandType::Right : EIslandRedBlueWeaponHandType::Left);
		return FTransform(FRotator::MakeFromX(GrenadeTarget - Weapon.Muzzle.WorldLocation), Weapon.Muzzle.WorldLocation);
	}
}

struct FIslandRedBlueStickyGrenadeThrowActivatedParams
{
	UIslandRedBlueTargetableComponent Targetable;
	FAimingResult AimTarget;
}