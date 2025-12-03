UCLASS(Abstract)
class AMonkeySmashElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxComp;
	default FauxComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = FauxComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent SlamMesh;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComponent;

	UPROPERTY(DefaultComponent, Attach = FauxComp, Category = "Audio")
	UHazeAudioComponent AudioComp;

	UPROPERTY(Category = "Audio")
	float AttenuationScaling = 5000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent FirstSlamEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent SecondSlamEvent;
	
	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent ThirdSlamEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent HitBottomEvent;

	private UHazeAudioEmitter AudioEmitter;
	private FHazeAudioPostEventInstance SlamEventInstance;

	bool bHasFallen = false;
	bool bHitGround = false;

	FHazeAcceleratedRotator RotationOffset;

	float DefaultSlamImpulse = 600;

	float Force = 25;

	float SlamImpulse;
	bool bSlamDone = false;

	private UHazeAudioEvent GetSlamEvent() const
	{		
		if(SlamImpulse == DefaultSlamImpulse * 2)
			return SecondSlamEvent;

		if(SlamImpulse == DefaultSlamImpulse * 4)
			return ThirdSlamEvent;

		return FirstSlamEvent;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		GroundSlamResponseComponent.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		FauxComp.OnConstraintHit.AddUFunction(this, n"OnConstraintHit");
		SlamImpulse = DefaultSlamImpulse;

		AudioEmitter = AudioComp.GetEmitter(this);
		AudioEmitter.SetAttenuationScaling(AttenuationScaling);
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		RotationOffset.SnapTo(RotationOffset.Value, FRotator(Force * (Math::RandBool() ? -1.0 : 1.0), 0, Force * (Math::RandBool() ? -1.0 : 1.0)));

		if(!HasControl())
			return;

		FauxComp.ApplyImpulse(FauxComp.WorldLocation, FVector::UpVector * -SlamImpulse);
		UHazeAudioEvent SlamEvent = GetSlamEvent();

		SlamImpulse *= 2;
		Timer::ClearTimer(this, n"SlamTimer");
		Timer::SetTimer(this, n"SlamTimer", 1.5);

		if(!bHitGround)
		{
			CrumbPlayAudioEvent(SlamEvent);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayAudioEvent(UHazeAudioEvent Event)
	{
		SlamEventInstance.Stop(500);
		SlamEventInstance = AudioEmitter.PostEvent(Event);
	}

	UFUNCTION()
	void SlamTimer()
	{
		SlamImpulse = DefaultSlamImpulse;
	}

	UFUNCTION(BlueprintEvent)
	void BP_SlamDone()
	{

	}

	UFUNCTION()
	void OnConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float Strength)
	{
		if (bHitGround)
		{
			FauxComp.OnConstraintHit.UnbindObject(this);
			return;	
		}

		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)	
		{
			AudioEmitter.PostEvent(HitBottomEvent);
			// if we unbind here it won't network the contrainhit.
			//FauxComp.OnConstraintHit.UnbindObject(this);

			bHitGround = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSlamDone)
		{
			RotationOffset.SpringTo(FRotator::ZeroRotator, 30.0, 0.2, DeltaSeconds);
			RotationRoot.RelativeRotation = RotationOffset.Value;
		}
		else
		{
			RotationOffset.AccelerateTo(FRotator::ZeroRotator, 1, DeltaSeconds);
			RotationRoot.RelativeRotation = RotationOffset.Value;
		}

		if(!HasControl())
			return;

		if (FauxComp.RelativeLocation.Z <= -600)
		{
			FauxComp.ApplyForce(FauxComp.WorldLocation, FVector::UpVector * -15000);

			if (!bSlamDone)
				CrumbOnSlamDone();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSlamDone()
	{
		bSlamDone = true;
		BP_SlamDone();
	}
}