event void FSkylineWhipPoleImpactSignature(FVector Location, FVector Normal, ASkylineWhipPole WhipPole);

class USkylineWhipPoleResponseComponent : UActorComponent
{
	UPROPERTY()
	FSkylineWhipPoleImpactSignature OnPoleImpact;
}

class USkylineWhipPoleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactEnforcer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFallOff() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFallOf() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLand() {}
}

class ASkylineWhipPole : APoleClimbActor
{
	default RootComp.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;
	default GravityWhipResponseComponent.ForceMultiplier = 2.0;
	default GravityWhipResponseComponent.ForwardAxis = FVector::UpVector;

	UPROPERTY(DefaultComponent)
	USwingPointComponent SwingPointComponent;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;	

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ZoeForceFeedBack; 

	UPROPERTY(EditAnywhere)
	float DetachTelegraph = 4.0;
	bool bDetachTelegraphed = false;

	UPROPERTY(EditAnywhere)
	float AttachDuration = 6.0;
	float MaxAttachDuration = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float DurationAlpha = 1.0;

	float MaxThrowDuration = 5.0;
	float FallDuration = 3.0;

	FVector Velocity;
	float Drag = 16.0;

	FVector ThrowDirection;
	
	bool bGrabbed = false;
	bool bThrown = false;
	bool bAttached = false;
	bool bFalling = false;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bCanDamagePlayer;

	float ThrowSpeed = 10000.0;

	UPlayerAimingComponent PlayerAimingComponent;

	FVector ImpactNormal;
	FVector AngluarVelocity;
	float AngularDrag = 6.0;

	FVector Gravity = FVector::UpVector * -980.0 * 4.0;

	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditAnywhere)
	TArray<FVector2D> Offsets;
	default Offsets.Add(FVector2D(200.0, 0.0));
	default Offsets.Add(FVector2D(-200.0, 0.0));

	FVector2D TargetOffset;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence EnforcerDeathAnim;

	TArray<AAISkylineEnforcerPatrol> HitEnforcers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		MaxAttachDuration = AttachDuration;

		RootComponent.SetMobility(EComponentMobility::Movable);

		Super::BeginPlay();

		DisablePole();

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");

		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartPerching");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Acceleration;
		FVector AngluarAcceleration;

		if (bGrabbed)
		{
			FVector GrabForce;

			for (auto& Grab : GravityWhipResponseComponent.Grabs)
				GrabForce += Grab.TargetComponent.ConsumeForce();

			Acceleration += GrabForce * 12.0
						  - Velocity * Drag;
		
			SetActorRotation(FQuat::MakeFromZ(-PlayerAimingComponent.GetPlayerAimingRay().Direction));			
		}

		if (bThrown)
		{
			MaxThrowDuration -= DeltaSeconds;
			if (MaxThrowDuration <= 0.0 && HasControl())
				CrumbDestroyActor();

			Velocity = ThrowDirection * ThrowSpeed;
			
			if (HasControl())
			{
				auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				//Trace.IgnorePlayers();
				Trace.IgnoreActor(this);
				Trace.IgnoreActors(ActorsToIgnore);
				FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + Velocity * DeltaSeconds);
				if (Hit.bBlockingHit)
				{
					CrumbHitImpact(Hit, Hit.Component.WorldTransform.InverseTransformPosition(Hit.ImpactPoint));
				}
			}
		}

		if (bAttached)
		{
			DetachTelegraph -= DeltaSeconds;
			if (DetachTelegraph <= 0.0 && !bDetachTelegraphed)
			{
				BP_PoleDetachTelegraph();
				bDetachTelegraphed = true;

				USkylineWhipPoleEventHandler::Trigger_OnStartFallOf(this);
			}

			AttachDuration -= DeltaSeconds;

			DurationAlpha = Math::Max(SMALL_NUMBER, AttachDuration / MaxAttachDuration);

			if (AttachDuration <= 0.0)
				PoleFallOff();

			AngluarAcceleration += ActorTransform.InverseTransformVector(ImpactNormal.CrossProduct(-ActorUpVector) * 250.0)
								 - AngluarVelocity * AngularDrag;
		}

		if (bFalling)
		{
			FallDuration -= DeltaSeconds;
			if (FallDuration <= 0.0 && HasControl())
				CrumbDestroyActor();

			Acceleration += Gravity
						  - Velocity;
		}

		AngluarVelocity += AngluarAcceleration * DeltaSeconds;
		Velocity += Acceleration * DeltaSeconds;

		AddActorWorldOffset(Velocity * DeltaSeconds);
		AddActorLocalRotation(FQuat(AngluarVelocity.GetSafeNormal(), AngluarVelocity.Size() * DeltaSeconds));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitImpact(FHitResult Hit, FVector RelativeImpactPoint)
	{
		// PrintToScreen("Impact!" + Hit.Actor, 1.0, FLinearColor::Green);
		auto SkylineWhipPoleResponseComponent = USkylineWhipPoleResponseComponent::Get(Hit.Actor);
		if (SkylineWhipPoleResponseComponent != nullptr)
		{
			SkylineWhipPoleResponseComponent.OnPoleImpact.Broadcast(Hit.Location, Hit.ImpactNormal, this);
		}
		else
		{	
			if (bCanDamagePlayer)
			{
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if (Player != nullptr)
					Player.KillPlayer();
			}

			auto WhipThrowResponseComp = UGravityWhipThrowResponseComponent::Get(Hit.Actor);
			if (WhipThrowResponseComp != nullptr)
			{
				auto EnforcerPatrol = Cast<AAISkylineEnforcerPatrol>(Hit.Actor);

				EnforcerPatrol.BlockCapabilities(n"Movement", this);
				EnforcerPatrol.SetActorRotation(ActorUpVector.Rotation());
				EnforcerPatrol.ActorLocation = ActorLocation + (EnforcerPatrol.ActorUpVector * -100.0);
				EnforcerPatrol.AttachToComponent(RootComp, AttachmentRule = EAttachmentRule::KeepWorld);
				EnforcerPatrol.RagdollComp.bAllowRagdoll.Apply(false, this);
				EnforcerPatrol.PlayOverrideAnimation(FHazeAnimationDelegate(), Animation = EnforcerDeathAnim, bLoop = true, BlendTime = 0.1);
				EnforcerPatrol.DisableComp.SetEnableAutoDisable(false);
				EnforcerPatrol.RespawnComp.OnUnspawn.AddUFunction(this, n"OnHitEnforcerUnspawned");
				HitEnforcers.AddUnique(EnforcerPatrol);

				FGravityWhipThrowHitData HitData;
				HitData.Damage = 100.0;
				HitData.Instigator = this;
				WhipThrowResponseComp.OnHit.Broadcast(HitData);

				ActorsToIgnore.Add(Hit.Actor);
				USkylineWhipPoleEventHandler::Trigger_OnImpactEnforcer(this);
				
				return;
			}

			auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(Hit.Actor);
			if (ImpactResponseComponent != nullptr)
			{
				FGravityWhipImpactData ImpactData;
				ImpactData.ImpactVelocity = Velocity;
				ImpactData.HitResult = Hit;
				ImpactResponseComponent.Impact(ImpactData);

				return;
			}

			// DestroyActor();
			PoleFallOff();
			return;
		}

		AttachToComponent(Hit.Component, AttachmentRule =  EAttachmentRule::KeepWorld);
		SetActorRelativeLocation(RelativeImpactPoint);
		ImpactNormal = Hit.ImpactNormal;

		EnablePole();
		PoleImpact();
	}

	UFUNCTION()
	private void OnHitEnforcerUnspawned(AHazeActor RespawnableActor)
	{
		auto HitEnforcer = Cast<AAISkylineEnforcerPatrol>(RespawnableActor);
		if (HitEnforcer == nullptr)
			return;

		HitEnforcers.Remove(HitEnforcer);

		ResetHitEnforcer(HitEnforcer);
	}

	void ResetHitEnforcer(AAISkylineEnforcerPatrol HitEnforcer)
	{
		HitEnforcer.RespawnComp.OnUnspawn.Unbind(this, n"OnHitEnforcerUnspawned");
		HitEnforcer.UnblockCapabilities(n"Movement", this);
		HitEnforcer.DetachFromActor();
		HitEnforcer.RagdollComp.bAllowRagdoll.Clear(this);
		HitEnforcer.StopOverrideAnimation(EnforcerDeathAnim);
		HitEnforcer.DisableComp.SetEnableAutoDisable(true);		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDestroyActor()
	{
		for (auto HitEnforcer : HitEnforcers)
			ResetHitEnforcer(HitEnforcer);
		
		DestroyActor();
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
		PlayerAimingComponent = UPlayerAimingComponent::Get(UserComponent.Owner);
		USkylineWhipPoleEventHandler::Trigger_OnGrabbed(this);

		if (OtherComponents.Num() == 1)
			return;

		// Get offset for this grab
		if (Offsets.Num() >= OtherComponents.Num())
			TargetOffset = Offsets[OtherComponents.FindIndex(TargetComponent)];

	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		bGrabbed = false;
		bThrown = true;

		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);

		FVector AimDirection = PlayerAimingComponent.GetPlayerAimingRay().Direction;

		PlayerAimingComponent = nullptr;

		ThrowDirection = Impulse.GetSafeNormal();

//		ThrowDirection = -ActorUpVector; // HAX

		FVector HitLocation = HitResult.TraceEnd;
		if (HitResult.bBlockingHit)
			HitLocation = HitResult.ImpactPoint;

		FVector HitNormal = (HitResult.TraceStart - HitResult.TraceEnd).SafeNormal;
		if (HitResult.bBlockingHit)
			HitNormal = HitResult.ImpactNormal;

		FTransform TargetTransform;
		TargetTransform.Location = HitLocation;
		TargetTransform.Rotation = FQuat::MakeFromZX(Player.ViewRotation.UpVector, HitNormal);
		TargetTransform.Scale3D = FVector::OneVector;

	//	Debug::DrawDebugSphere(TargetTransform.Location, 200.0, 12, FLinearColor::Green, 5.0, 5.0);
	//	Debug::DrawDebugCoordinateSystem(TargetTransform.Location, TargetTransform.Rotator(), 2000.0, 20.0, 5.0);

		FVector TargetLocation = TargetTransform.TransformPositionNoScale(FVector(0.0, TargetOffset.X, TargetOffset.Y)); 

		ThrowDirection = (TargetLocation - ActorLocation).SafeNormal;

//		ThrowDirection = AimDirection;

		GravityWhipTargetComponent.Disable(this);

		// Ignore rest of the stuff were throwing
		for (auto Grab : UserComponent.Grabs)
			ActorsToIgnore.Add(Grab.Actor);

		USkylineWhipPoleEventHandler::Trigger_OnThrown(this);
			
	//	PrintToScreen("Thrown!", 1.0, FLinearColor::Green);
	}

	UFUNCTION()
	void OnPlayerStartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchComp)
	{
		USkylineWhipPoleEventHandler::Trigger_OnPlayerLand(this);
	}

	void DisablePole()
	{
		PerchPointComp.Disable(this);
		PerchEnterZone.DisableTrigger(this);
		EnterZone.DisableTrigger(this);
		SwingPointComponent.Disable(this);
	}

	void EnablePole()
	{
		PerchPointComp.Enable(this);
		PerchEnterZone.EnableTrigger(this);
		EnterZone.EnableTrigger(this);

		// if (ImpactNormal.DotProduct(-Game::Mio.MovementWorldUp) > 0.7)
		// {
		// 	SwingPointComponent.Enable(this);
		// }
	}

	void PoleImpact()
	{
		USkylineWhipPoleEventHandler::Trigger_OnImpact(this);
		Velocity = FVector::ZeroVector;
		bThrown = false;
		bAttached = true;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		Game::Zoe.PlayForceFeedback(ZoeForceFeedBack, false, false, this, 1.0);
		BP_PoleImpact();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PoleImpact()
	{
	}

	void PoleFallOff()
	{
		bThrown = false;
		bAttached = false;
		bFalling = true;

		Velocity = ActorUpVector * Math::RandRange(500.0, 800.0);
		AngluarVelocity = ActorTransform.InverseTransformVector(ActorUpVector.CrossProduct(-FVector::UpVector) * Math::RandRange(2.0, 5.0));

		USkylineWhipPoleEventHandler::Trigger_OnFallOff(this);

		DisablePole();

		BP_PoleFallOff();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PoleFallOff()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_PoleDetachTelegraph()
	{
	}	
}