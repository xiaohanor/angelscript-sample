//Shrink down and set only as a response component (probably) when replacing with official destruction actors
class UBattlefieldBreakableObjectComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float CameraShakeMultiplier = 1.0;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakSystem;

	UPROPERTY(EditAnywhere)
	bool bCanShrink = true;

	UPROPERTY(EditAnywhere)
	float ShrinkDelay = 3.0;

	UPROPERTY(EditAnywhere)
	float ShrinkSpeedMultiplier = 1.5;

	UPROPERTY(EditAnywhere)
	bool bIgnorePlayerCollision = true;

	TArray<UStaticMeshComponent> MeshComps;

	int Count;
	
	float ShrinkTime = 1.0;

	bool bCanExcludeExemptMeshes = false;
	bool bCanBreak;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(MeshComps);
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bCanShrink)
			return;
		
		if (Time::GameTimeSeconds < ShrinkTime)
			return;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (bCanExcludeExemptMeshes)
			{
				UBattlefieldExemptDestructionMeshComponent ExemptMesh = Cast<UBattlefieldExemptDestructionMeshComponent>(Mesh);

				if (ExemptMesh != nullptr)
					continue;
			}

			FVector NewScale = Mesh.GetWorldScale() - (Mesh.GetWorldScale() * ShrinkSpeedMultiplier * DeltaSeconds);
			Mesh.SetWorldScale3D(NewScale);
		}			
	}

	UFUNCTION()
	void BreakBattlefieldObject(FVector ImpactDirection, float ImpulseAmount, bool bExcludeExemptMeshes = true)
	{
		bCanExcludeExemptMeshes = bExcludeExemptMeshes;

		FBattlefieldBreakObjectParams Params;
		Params.Location = Owner.ActorLocation;
		Params.System = BreakSystem;
		UBattlefieldBreakableObjectEffectHandler::Trigger_OnObjectBreak(Cast<AHazeActor>(Owner), Params);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (bExcludeExemptMeshes)
			{
				UBattlefieldExemptDestructionMeshComponent ExemptMesh = Cast<UBattlefieldExemptDestructionMeshComponent>(Mesh);

				if (ExemptMesh != nullptr)
					continue;
			}

			Mesh.SetSimulatePhysics(true);

			if (ImpactDirection.Size() == 0)
				Mesh.AddImpulse((Mesh.WorldLocation - Owner.ActorLocation).GetSafeNormal() * ImpulseAmount);
			else
				Mesh.AddImpulse(ImpactDirection * ImpulseAmount);
		}

		for (UStaticMeshComponent Mesh : MeshComps)
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		
		Game::Mio.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
		Game::Zoe.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
		ShrinkTime = Time::GameTimeSeconds + ShrinkDelay;
		SetComponentTickEnabled(true);
	}
}