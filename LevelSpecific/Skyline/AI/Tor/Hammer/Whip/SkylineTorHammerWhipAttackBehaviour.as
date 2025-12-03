
class USkylineTorHammerWhipAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	UGravityWhipTargetComponent WhipTarget;
	USkylineTorHammerWhipComponent WhipComp;
	USkylineTorSettings Settings;

	private AHazeActor Target;
	private bool bPostSetupDone;
	float HitTime;
	FVector ThrowImpulse;
	float MaxTime = 1.5;
	float Alpha;
	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedRotator AccRot;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Owner);
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
		
		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);

		if(PrimaryTarget != nullptr && PrimaryTarget.Owner.IsA(ASkylineTor))
		{
			WhipComp.bAttack = true;
			FVector AimDir = Impulse.GetSafeNormal();
			ThrowImpulse = AimDir * Impulse.Size();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!WhipComp.bAttack)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		Owner.AddActorCollisionBlock(this);
		Alpha = 0;
		AccSpeed.SnapTo(0);
		AccRot.SnapTo(Owner.ActorRotation);
		StartLocation = Owner.ActorLocation;
		HitTime = 0;
		WhipComp.bAttack = false;
		WhipComp.bThrow = false;
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
		if(HitTime > 0)
		{
			if(Time::GetGameTimeSince(HitTime) > 0.25)
				DeactivateBehaviour();
			return;
		}

		AccSpeed.AccelerateTo(3, 0.25, DeltaTime);
		Alpha += DeltaTime * AccSpeed.Value;

		if (HammerComp.HoldHammerComp == nullptr)
			return;

		FVector TargetLocation = HammerComp.HoldHammerComp.Tor.ActorCenterLocation - (HammerComp.HoldHammerComp.Tor.ActorCenterLocation - StartLocation).GetSafeNormal() * 300;
		FVector ForwardVector = (TargetLocation - StartLocation).GetSafeNormal();
		FVector OffsetDir = (TargetLocation - StartLocation).Rotation().RightVector;
		FVector MidLocation = TargetLocation + OffsetDir * 600;
		Owner.ActorLocation = BezierCurve::GetLocation_1CP(StartLocation, MidLocation, TargetLocation, Alpha);
		AccRot.AccelerateTo(ForwardVector.Rotation() + FRotator(-70, 0, 0), 0.5, DeltaTime);
		Owner.ActorRotation = AccRot.Value;

		if(Alpha >= 1)
		{
			FHitResult Hit = FHitResult();
			Hit.Location = TargetLocation;
			if(HasControl())
				CrumbHitCharacter(HammerComp.HoldHammerComp.Tor, Hit);
		}
	}
	
	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbHitCharacter(AHazeActor Character, FHitResult Hit)
	{
		HitTime = Time::GameTimeSeconds;
		OnHitCharacter(Hit);
		HitCharacter(Character, Hit);
	}

	void HitCharacter(AHazeActor Character, FHitResult Hit)
	{
		USkylineTorHammerEventHandler::Trigger_OnAttackHit(Owner, FSkylineTorHammerOnAttackHitEventData(Hit));
		USkylineTorHammerResponseComponent ResponseComp = USkylineTorHammerResponseComponent::Get(Character);
		if(ResponseComp != nullptr)
			ResponseComp.OnHit.Broadcast(1, EDamageType::MeleeBlunt, Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitCharacter(FHitResult Hit) {}
}