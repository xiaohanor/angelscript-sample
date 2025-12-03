UCLASS(Abstract)
class AMeltdownPhaseThreeBallDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent VFX_Looping;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.bApplyKnockbackImpulse = true;
	default DamageTrigger.HorizontalKnockbackStrength = 900.0;
	default DamageTrigger.VerticalKnockbackStrength = 1200.0;

	UPROPERTY()
	TArray<UStaticMesh> Meshes;

	AMeltdownPhaseThreeBoss Rader;

	const float Gravity = 5000.0;
	const float Height = 1000.0;

	FVector Velocity;
	float Timer;

	FRotator StartRotation;
	FRotator RotationSpeed;

	bool bDestroying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Launch(FRandomStream RandomStream)
	{
		Mesh.SetStaticMesh(
			Meshes[RandomStream.RandRange(0, Meshes.Num()-1)]
		);
		Mesh.SetRelativeScale3D(
			FVector(DamageTrigger.Shape.SphereRadius / Mesh.StaticMesh.Bounds.SphereRadius)
		);

		StartRotation = ActorRotation;
		RotationSpeed = FRotator::MakeFromEuler(
			RandomStream.VRand() * RandomStream.RandRange(100.0, 150.0),
		);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		FVector NewLocation = ActorLocation;
		NewLocation += Velocity * DeltaSeconds;
		NewLocation += FVector(0, 0, -Gravity) * 0.5 * Math::Square(DeltaSeconds);

		if (NewLocation.Z < Rader.ActorLocation.Z + 175.0 && Velocity.Z < 0.0)
		{
			if (Rader.ActorLocation.Dist2D(NewLocation) < Rader.ArenaRadius)
			{
				NewLocation.Z = Rader.ActorLocation.Z + 175.0;
				Velocity.Z *= -0.6;

				if (Velocity.Z < 50.0)
				{
					bDestroying = true;
				}
			}
		}

		SetActorLocationAndRotation(
			NewLocation,
			StartRotation + RotationSpeed * Timer
		);

		Velocity.Z -= Gravity * DeltaSeconds;
		
		if (Timer > 5.0)
		{
			bDestroying = true;
		}

		if (bDestroying)
		{
			SetActorScale3D(
				Math::VInterpConstantTo(
					GetActorScale3D(), FVector(0.01), DeltaSeconds, 5.0,
				)
			);

			if (GetActorScale3D().X <= 0.05)
			{
				Mesh.SetVisibility(false);
				DamageTrigger.DisableDamageTrigger(this);
				VFX_Looping.Deactivate();
				Timer::SetTimer(this, n"Removeffect", 1.0);
			}
		}
	}

	UFUNCTION()
	private void Removeffect()
	{
		DestroyActor();
	}
};