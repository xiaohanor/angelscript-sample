class USkylineTorHammerStealComponent : UActorComponent
{
	UGravityBladeCombatResponseComponent BladeResponse;
	UGravityWhipResponseComponent WhipResponse;
	UGravityWhipTargetComponent WhipTarget;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	UGravityBladeGrappleComponent GrappleComp;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerGrabMashComponent GrabMashComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerStateManager HammerStateManager;
	USkylineTorSettings Settings;

	FInstigator Instigator;
	bool bEnabled;
	bool bEnableShieldBreak;
	float Duration;
	float InitialDuration;
	float ExtensionDuration;
	bool bBladeExtendedDuration;
	bool bMashExtendedDuration;
	float StartTime;
	float BladeDamage;
	bool bShieldBroken;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		GrabMashComp = USkylineTorHammerGrabMashComponent::GetOrCreate(Owner);
		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::GetOrCreate(Owner);
		GrappleComp = UGravityBladeGrappleComponent::GetOrCreate(Owner);
		HammerStateManager = USkylineTorHammerStateManager::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Cast<AHazeActor>(Owner));
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{		
		if(!Settings.ShieldBreakModeEnabled)
			return;

		if(!bEnabled)
			return;

		if(!bBladeExtendedDuration)
		{
			Extend(ExtensionDuration);
			bBladeExtendedDuration = true;
		}
		
		GravityBladeTutorial::HideCombatGrappleTutorial(Game::Mio);
		USkylineTorHammerEventHandler::Trigger_OnBladeHit(Cast<AHazeActor>(Owner), FSkylineTorHammerEventHandlerOnBladeHitData(HitData));

		if(!bEnableShieldBreak)
			return;

		bool KillingBlow = HealthComp.CurrentHealth - BladeDamage <= SMALL_NUMBER;
		if(!KillingBlow)
		{
			HealthComp.TakeDamage(BladeDamage, EDamageType::Default, Cast<AHazeActor>(CombatComp.Owner));
			return;
		}

		Extend(ExtensionDuration);

		HealthBarComp.SetHealthBarEnabled(false);
		HealthComp.SetInvulnerable();

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);
		FStumble Stumble;
		FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		Stumble.Move = Dir * 200;
		Stumble.Duration = 0.5;
		Player.ApplyStumble(Stumble);

		HammerComp.HoldHammerComp.Hammer.ShieldMesh.SetVisibility(false, true);
		USkylineTorHammerEventHandler::Trigger_OnShieldBreak(Cast<AHazeActor>(Owner), FSkylineTorHammerEventHandlerShieldBreakData(HitData, HammerComp.HoldHammerComp.Hammer.SlingAutoAimComp));

		bEnableShieldBreak = false;
		HammerStateManager.EnableWhipTargetComp(Instigator);
		HammerComp.HoldHammerComp.Hammer.BladeOutline.BlockOutline(this);
		HealthComp.Reset();
		bShieldBroken = true;
	}

	void InitializeStealing()
	{
		HammerComp.HoldHammerComp.Hammer.ShieldMesh.SetVisibility(true, true);
	}

	void EnableStealing(FInstigator _Instigator, float _Duration, float _ExtensionDuration, float _BladeDamage)
	{
		Instigator = _Instigator;
		Duration = _Duration;
		InitialDuration = _Duration;
		ExtensionDuration = _ExtensionDuration;
		bEnabled = true;
		bEnableShieldBreak = true;
		bShieldBroken = false;
		StartTime = Time::GameTimeSeconds;
		bBladeExtendedDuration = false;
		bMashExtendedDuration = false;
		BladeDamage = _BladeDamage;

		if(Settings.ShieldBreakModeEnabled)
		{
			HammerStateManager.ClearWhipTargetComp(Instigator);
			HammerStateManager.EnableBladeTargetComp(Instigator);
			HammerStateManager.EnableBladeGrappleComp(Instigator);
			HammerComp.HoldHammerComp.Hammer.ShieldMesh.SetVisibility(true, true);

			HealthComp.RemoveInvulnerable();

			float Offset = -100;
			if(HammerComp.CurrentMode == ESkylineTorHammerMode::Melee || HammerComp.CurrentMode == ESkylineTorHammerMode::MeleeSecond)
				Offset = 400;
			UBasicAIHealthBarSettings::SetHealthBarOffset(HammerComp.HoldHammerComp.Hammer, FVector::UpVector * Offset, this, EHazeSettingsPriority::Script);
			
			HealthBarComp.SetHealthBarEnabled(true);
			HealthBarComp.UpdateHealthBarSettings();
		}
		else
		{
			HammerStateManager.EnableWhipTargetComp(Instigator);
		}
	}

	void DisableStealing(FInstigator DisableInstigator)
	{
		if(!bEnabled)
			return;

		bEnabled = false;

		HammerStateManager.ClearWhipTargetComp(DisableInstigator);
		HammerStateManager.ClearBladeTargetComp(DisableInstigator);
		HammerComp.HoldHammerComp.Hammer.BladeOutline.UnblockOutline(this);
		HammerStateManager.ClearBladeGrappleComp(DisableInstigator);

		GrabMashComp.StopMash(WhipResponse);		
		HammerComp.HoldHammerComp.Hammer.ShieldMesh.SetVisibility(false, true);
		HealthBarComp.SetHealthBarEnabled(false);
		USkylineTorHammerEventHandler::Trigger_OnShieldStop(Cast<AHazeActor>(Owner));
	}

	bool IsStealingExpired()
	{
		return Duration >= 0 && Time::GetGameTimeSince(StartTime) > Duration;
	}

	float GetRemainingDuration()
	{
		return Duration - Time::GetGameTimeSince(StartTime);
	}

	void Extend(float _ExtendDuration)
	{
		if(_ExtendDuration > 0)
		{
			StartTime = Time::GameTimeSeconds;
			Duration = Math::Min(InitialDuration, Duration + _ExtendDuration);
		}
	}
}