UCLASS(Abstract)
class AArenaCenterPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CenterRoot;

	UPROPERTY(DefaultComponent, Attach = CenterRoot)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(5.0);

	UPROPERTY(EditAnywhere)
	bool bPlatformGatesOpen = true;

	UPROPERTY(EditAnywhere)
	bool bPlatformsSpread = false;

	FHazeAcceleratedFloat AccRotationSpeed;
	float DesiredSpeed = 9.0;
	float TargetSpeed = 0.0;

	bool bSpinning = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		auto Platforms = Editor::GetAllEditorWorldActorsOfClass(AArenaPlatform);
		for (auto It : Platforms)
		{
			AArenaPlatform Platform = Cast<AArenaPlatform>(It);
			FHitResult DummyHit;
			float XOffset = 0.0;
			float YOffset = 0.0;
			if (bPlatformsSpread)
			{
				XOffset = Platform.Spread.X;
				YOffset = Platform.Spread.Y;
			}

			Platform.PlatformRoot.SetRelativeLocation(FVector(XOffset, YOffset, 0.0), false, DummyHit, true);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AArenaPlatform> Platforms;
		for (AArenaPlatform Platform : Platforms)
		{
			Platform.AttachToComponent(CenterRoot, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccRotationSpeed.AccelerateTo(TargetSpeed, 5.0, DeltaTime);
		AddActorLocalRotation(FRotator(0.0, AccRotationSpeed.Value * DeltaTime, 0.0));
	}

	UFUNCTION(DevFunction)
	void StartSpinning()
	{
		bSpinning = true;
		TargetSpeed = DesiredSpeed;
	}

	UFUNCTION(DevFunction)
	void StopSpinning()
	{
		bSpinning = false;
		TargetSpeed = 0.0;
	}

	UFUNCTION()
	void UpdateDesiredSpeed(float Speed)
	{
		DesiredSpeed = Speed;
	}
}