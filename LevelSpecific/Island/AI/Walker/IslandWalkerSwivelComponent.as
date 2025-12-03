class UIslandWalkerSwivelComponent : USceneComponent
{
	AHazeActor HazeOwner;

	float SwivelYaw = 0.0;

	bool bHasSwivelled = false;
	float SwivelVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(WorldLocation, WorldLocation + ForwardVector * 2000, FLinearColor::Red, 10);
			Debug::DrawDebugLine(WorldLocation - FVector(0,0,50), WorldLocation - FVector(0,0,50) + Cast<AHazeCharacter>(Owner).Mesh.GetSocketRotation(n"SpineBase").ForwardVector * 2000, FLinearColor::Green, 10);
		}
#endif

		if (HazeOwner.bIsControlledByCutscene)
		{
			SwivelYaw = 0.0;
			SwivelVelocity = 0.0;
			bHasSwivelled = true;
		}

		if (!bHasSwivelled && Math::IsNearlyZero(SwivelVelocity, 0.01))
			return;

		if (!bHasSwivelled)
			SwivelVelocity *= Math::Pow(Math::Exp(-2.0), DeltaTime);

		bHasSwivelled = false;

		SwivelYaw += SwivelVelocity * DeltaTime;
	}

	void Swivel(float Velocity)
	{
		if (!ensure(!bHasSwivelled))
			return;
		bHasSwivelled = true;
		SwivelVelocity = Velocity;
	}

	void Realign(float Duration, float DeltaTime)
	{
		if (!ensure(!bHasSwivelled))
			return;
		bHasSwivelled = true;
		FHazeAcceleratedFloat AccSwivel;
		AccSwivel.Value = FRotator::NormalizeAxis(SwivelYaw);
		AccSwivel.AccelerateTo(0.0, Duration, DeltaTime);
		SwivelYaw = AccSwivel.Value;
		SwivelVelocity = AccSwivel.Velocity;
	}
}
