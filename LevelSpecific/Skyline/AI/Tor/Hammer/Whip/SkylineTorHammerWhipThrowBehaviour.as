
class USkylineTorHammerWhipThrowBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerProjectileComponent ProjectileComp;
	USkylineTorHammerPivotComponent PivotComp;
	UGravityWhipTargetComponent WhipTarget;
	UBasicAIHomingProjectileComponent HomingProjectileComp;
	USkylineTorHammerWhipComponent WhipComp;
	USkylineTorSettings Settings;

	private AHazeActor Target;
	private bool bPostSetupDone;
	FVector ThrowImpulse;
	float MaxTime = 1.5;
	bool bStopHoming = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		ProjectileComp = USkylineTorHammerProjectileComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Owner);
		HomingProjectileComp = UBasicAIHomingProjectileComponent::GetOrCreate(Owner);
		WhipComp = USkylineTorHammerWhipComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);

		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
	                      UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                      FVector Impulse)
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::Whipped)
			return;
		
		WhipComp.bThrow = true;

		FVector AimDir = Impulse.GetSafeNormal();
		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);
		if(PrimaryTarget != nullptr)
		{
			if(HomingProjectileComp != nullptr)
				HomingProjectileComp.Target = Cast<AHazeActor>(PrimaryTarget.Owner);

			AimDir = (Cast<AHazeActor>(PrimaryTarget.Owner).FocusLocation - Owner.ActorLocation).GetSafeNormal();
		}
		else
		{
			HomingProjectileComp.Target = nullptr;
		}

		ThrowImpulse = AimDir * Impulse.Size();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!WhipComp.bThrow)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		bStopHoming = false;
		WhipComp.bAttack = false;
		WhipComp.bThrow = false;
		
		ProjectileComp.AdditionalIgnoreActors.Empty();
		ProjectileComp.AdditionalIgnoreActors.Add(Owner);

		ProjectileComp.Reset();
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceZoe;
		ProjectileComp.Launch(ThrowImpulse);
		ProjectileComp.Gravity = 0;

		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!StopHoming())
		{
			float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			ProjectileComp.Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, ProjectileComp.Velocity.GetSafeNormal(), 300.0 * Math::Min(1, LaunchDuration)) * DeltaTime;
			bStopHoming = Owner.ActorLocation.IsWithinDist(TargetLocation, 50);
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		Owner.SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, false, 0.005));
		Owner.SetActorRotation(ProjectileComp.Velocity.Rotation() + FRotator(-90, 0, 0));

		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			bool bIsCharacter = (Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazeCharacter));
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;

			if (Controller.HasControl())	
			{
				if(bIsCharacter)
					CrumbHitCharacter(Cast<AHazeCharacter>(Hit.Actor), Hit);
				else
					CrumbImpact(Hit); 
			}
			else
			{
				// Visual impact only
				if(bIsCharacter)
				{
					OnLocalHitCharacter(Hit);
					USkylineTorHammerEventHandler::Trigger_OnImpactHit(Owner, FSkylineTorHammerOnHitEventData(Hit));
				}
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

	private bool StopHoming()
	{
		if(ProjectileComp.Launcher == nullptr)
			return true;
		if(HomingProjectileComp == nullptr)
			return true;
		if(HomingProjectileComp.Target == nullptr)
			return true;
		if(bStopHoming)
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
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
		bStopHoming = true;
		USkylineTorHammerEventHandler::Trigger_OnImpactHit(Owner, FSkylineTorHammerOnHitEventData(Hit));

		USkylineTorHammerResponseComponent ResponseComp = USkylineTorHammerResponseComponent::Get(Character);
		if(ResponseComp != nullptr)
			ResponseComp.OnHit.Broadcast(ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);

		DeactivateBehaviour();
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