
class USkylineTorHammerVolleyMoveBehaviour : UBasicBehaviour
{	
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerProjectileComponent ProjectileComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorTelegraphLightComponent TelegraphLightComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorSettings Settings;

	private AHazePlayerCharacter Target;
	private bool bPostSetupDone;
	private bool bCompleted;
	float MaxTime = 5.0;
	bool bLanded;
	FHazeAcceleratedRotator AccRotation;
	bool bTickSetup;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		ProjectileComp = USkylineTorHammerProjectileComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		TelegraphLightComp = USkylineTorTelegraphLightComponent::GetOrCreate(HammerComp.HoldHammerComp.Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		HammerComp.OnChangedMode.AddUFunction(this, n"ChangedMode");
	}

	UFUNCTION()
	private void ChangedMode(ESkylineTorHammerMode NewMode, ESkylineTorHammerMode OldMode)
	{
		if(NewMode == ESkylineTorHammerMode::Volley)
			bCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTickSetup = false;
	}

	private void TickSetup()
	{
		ProjectileComp.AdditionalIgnoreActors.Empty();
		ProjectileComp.AdditionalIgnoreActors.Add(Owner);
		ProjectileComp.AdditionalIgnoreActors.Add(HammerComp.HoldHammerComp.Owner);

		bLanded = false;
		bTickSetup = true;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		ProjectileComp.Reset();
		float Gravity = 3000.0;
		PivotComp.SetPivot(HammerComp.HoldHammerComp.Hammer.TopLocation.WorldLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(PivotComp.Pivot.ActorLocation, VolleyComp.TargetLocation, Gravity, 500);
		ProjectileComp.Launch(LaunchVelocity);
		ProjectileComp.Gravity = Gravity;
		Owner.AddActorCollisionBlock(this);
		USkylineTorHammerEventHandler::Trigger_OnVolleyThrow(Owner, FSkylineTorHammerOnVolleyTelegraphStartData(VolleyComp.TargetLocation));
		TelegraphLightComp.Start(VolleyComp.TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.RemoveActorCollisionBlock(this);
		ProjectileComp.Reset();
		bCompleted = true;
		TargetComp.SetTarget(nullptr);
		TelegraphLightComp.Stop();
		PivotComp.RemovePivot();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::Volley)
			return;

		// Doing it like these because we want to do stuff indepently on remote, but we are stuck in a crumbed compound
		if(!bTickSetup)
		{
			TickSetup();
			return;
		}

		if(bLanded)
			return;

		bool bIgnoreCollision = ProjectileComp.Velocity.Z > 0;
		FHitResult Hit;
		PivotComp.Pivot.SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, bIgnoreCollision, 0.005));
		AccRotation.AccelerateTo(ProjectileComp.Velocity.Rotation() + FRotator(-90, 0, 0), 0.2, DeltaTime);
		PivotComp.Pivot.SetActorRotation(AccRotation.Value);

		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			bool bIsCharacter = (Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazeCharacter));
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;

			if(bIsCharacter)
			{
				if (Controller.HasControl())
					CrumbHitCharacter(Cast<AHazeCharacter>(Hit.Actor), Hit);
				else
				{
					OnLocalHitCharacter(Hit);
					USkylineTorHammerEventHandler::Trigger_OnImpactHit(Owner, FSkylineTorHammerOnHitEventData(Hit));
				}
			}
			else
			{
				if(HasControl())
					CrumbImpact(Hit, PivotComp.Pivot.ActorLocation, PivotComp.Pivot.ActorRotation);
				else
				{
					OnLocalImpact(Hit);
					DeactivateBehaviour();
				}
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > MaxTime)
			DeactivateBehaviour();
	}

	UFUNCTION(CrumbFunction)
	void CrumbImpact(FHitResult Hit, FVector Location, FRotator Rotation)
	{
		PivotComp.Pivot.SetActorLocation(Location);
		PivotComp.Pivot.SetActorRotation(Rotation);
		bLanded = true;
		OnImpact(Hit);
		Impact(Hit);
	}

	void Impact(FHitResult Hit)
	{
		USkylineTorHammerEventHandler::Trigger_OnImpactLand(Owner, FSkylineTorHammerOnHitEventData(Hit));
		DeactivateBehaviour();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbHitCharacter(AHazeCharacter Character, FHitResult Hit)
	{
		OnHitCharacter(Hit);
		HitCharacter(Character, Hit);
	}

	void HitCharacter(AHazeCharacter Character, FHitResult Hit)
	{
		USkylineTorHammerEventHandler::Trigger_OnImpactHit(Owner, FSkylineTorHammerOnHitEventData(Hit));

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Character);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(ProjectileComp.Damage, DamageEffect = HammerComp.DamageEffect, DeathEffect = HammerComp.DeathEffect);

			FStumble Stumble;
			FVector Dir = ProjectileComp.Launcher.ActorForwardVector + FVector(0, 0, 0.2);
			Stumble.Move = Dir * 500;
			Stumble.Duration = 0.25;
			Player.ApplyStumble(Stumble);
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitCharacter(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent)
	void OnLocalHitCharacter(FHitResult Hit) {}
}