class ASkylineHighwayBossVehicleHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTargetComp;
	default BladeTargetComp.RelativeLocation = FVector(0, 0, 350);
	default BladeTargetComp.bOverrideTargetRange = true;
	default BladeTargetComp.TargetRange = 800;
	default BladeTargetComp.bCanRushTowards = false;
	default BladeTargetComp.SuctionMinimumDistance = 325;
	default BladeTargetComp.bOverrideSuctionReachDistance = true;
	default BladeTargetComp.SuctionReachDistance = 325;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeCombatInteractionResponseComp;
	default BladeCombatInteractionResponseComp.InteractionType = EGravityBladeCombatInteractionType::VerticalUp;

	UPROPERTY(DefaultComponent)
	UBoxComponent BladeCollisionComp;
	default BladeCollisionComp.RelativeLocation = FVector(0, 0, 250);
	default BladeCollisionComp.BoxExtent = FVector(200, 200, 50);

	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineHighwayBossVehicleHatchSection> HatchSections;

	UPROPERTY(EditInstanceOnly)
	AHazeActor InterfaceTarget;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	float AttenuationScaling = 8000;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UHazeAudioEvent HatchOpenAudioEvent;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UHazeAudioEvent HatchCloseAudioEvent;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	UHazeAudioEvent SlingableDispenseEvent;

	private UHazeAudioEmitter AudioEmitter;

	float OpenTime;
	bool bOpening;
	bool bOpen;
	bool bHasStartedClosing = false;
	USkylineInterfaceComponent InterfaceComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bool SetFunctions = false;
		BladeOutlineComp.AddComponentToOutline(HatchSections[0].MeshAdd);
		for(ASkylineHighwayBossVehicleHatchSection Hatch : HatchSections)
		{
			if(!SetFunctions)
			{
				SetFunctions = true;
				Hatch.AxisRotateComp.OnMinConstraintHit.AddUFunction(this, n"Closed");
				Hatch.AxisRotateComp.OnMaxConstraintHit.AddUFunction(this, n"Opened");
			}
		}

		BladeResponseComp.OnHit.AddUFunction(this, n"BladeHit");

		InterfaceComp = USkylineInterfaceComponent::GetOrCreate(InterfaceTarget);

		if(HatchOpenAudioEvent != nullptr
		|| HatchCloseAudioEvent != nullptr)
		{
			FHazeAudioEmitterAttachmentParams EmitterParams;
			EmitterParams.Attachment = BladeCollisionComp;
			EmitterParams.Instigator = this;
			EmitterParams.Owner = this;
			
			AudioEmitter = Audio::GetPooledEmitter(EmitterParams);
			AudioEmitter.SetAttenuationScaling(AttenuationScaling);
		}
	}

	UFUNCTION()
	private void Opened(float Strength)
	{
		if(bOpen)
			return;
		bOpen = true;
		InterfaceComp.OnActivated.Broadcast(this);
	}

	UFUNCTION()
	private void Closed(float Strength)
	{
		bOpening = false;
		bOpen = false;
		BladeOutlineComp.UnblockOutline(this);
		BladeTargetComp.Enable(this);
	}

	UFUNCTION()
	private void BladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(bOpening)
			return;
		bOpening = true;
		bOpen = false;
		OpenTime = Time::GameTimeSeconds;
		BladeOutlineComp.BlockOutline(this);
		BladeTargetComp.Disable(this);

		for(ASkylineHighwayBossVehicleHatchSection Hatch : HatchSections)
		{
			Hatch.AxisRotateComp.ApplyImpulse(ActorLocation + FVector::UpVector * 200, ActorForwardVector * 1000);
			Hatch.AddActorCollisionBlock(this);
		}
		
		if(HatchOpenAudioEvent != nullptr)
			AudioEmitter.PostEvent(HatchOpenAudioEvent);

		if(SlingableDispenseEvent != nullptr)
			AudioEmitter.PostEvent(SlingableDispenseEvent);

		bHasStartedClosing = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(OpenTime < SMALL_NUMBER)
			return;

		for(ASkylineHighwayBossVehicleHatchSection Hatch : HatchSections)
		{
			if(Time::GetGameTimeSince(OpenTime) < 1)
			{
				Hatch.AxisRotateComp.ApplyForce(ActorLocation + FVector::UpVector * 200, ActorForwardVector * 1500);
			}
			else
			{
				Hatch.AxisRotateComp.ApplyForce(ActorLocation + FVector::UpVector * 200, ActorForwardVector * -1000);
				Hatch.RemoveActorCollisionBlock(this);

				if(!bHasStartedClosing)	
				{
					if(HatchCloseAudioEvent != nullptr)
						AudioEmitter.PostEvent(HatchCloseAudioEvent);
				}

				bHasStartedClosing = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(AudioEmitter != nullptr)
			Audio::ReturnPooledEmitter(this, AudioEmitter);
	}
}

class ASkylineHighwayBossVehicleHatchSection : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default AxisRotateComp.LocalRotationAxis = FVector(0, 1, 0);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.RelativeLocation = FVector(0, 0, 200);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshAdd;
	default MeshAdd.RelativeLocation = FVector(0, 0, 200);
}