

UCLASS(Abstract)
class UTreeGuardianRangedShootEffectEventHandler : UTreeGuardianBaseEffectEventHandler
{
	UPROPERTY(EditAnywhere)
	UNiagaraSystem VFX_Asset_Grapple;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem VFX_Asset_GrappleDissolve;

	UNiagaraComponent VFX_Comp_Grapple;
	UNiagaraComponent VFX_Comp_GrappleDissolve;

	AHazeActor ProjectileTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnRangedShootStartPullingProjectile(FTundraPlayerTreeGuardianRangedShootParams Params)
	{
		//Print("Pulling projectile");

		ProjectileTarget = Params.Projectile;

		VFX_Comp_Grapple = Niagara::SpawnOneShotNiagaraSystemAttached(VFX_Asset_Grapple, TreeGuardianActor.Mesh, n"RightHand");
		VFX_Comp_Grapple.SetTickGroup(ETickingGroup::TG_LastDemotable);
		VFX_Comp_Grapple.TickBehavior = ENiagaraTickBehavior::UseComponentTickGroup;

		// UStaticMeshComponent MeshTarget = UStaticMeshComponent::Get(Params.Projectile);
		// if(MeshTarget != nullptr)
		// {
		// 	Niagara::OverrideSystemUserVariableStaticMeshComponent(VFX_Comp_Grapple, "TargetMesh", MeshTarget);
		// }

		UpdateGrapple();

		TimestampGrappleStarted = Time::GetGameTimeSeconds();
	}

	float TimestampGrappleStarted = -1.0;

	UFUNCTION(BlueprintOverride)
	void OnRangedShootShootProjectile(FTundraPlayerTreeGuardianRangedShootParams Params)
	{
		//Print("Shooting projectile");

		VFX_Comp_Grapple.Deactivate();

		VFX_Comp_GrappleDissolve = Niagara::SpawnOneShotNiagaraSystemAttached(VFX_Asset_GrappleDissolve, TreeGuardianActor.Mesh, n"None");
		ProjectileTarget = Params.Projectile;

		UpdateGrappleDissolve();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateGrapple();
		UpdateGrappleDissolve();
	}

	void UpdateGrapple()
	{
		if(VFX_Comp_Grapple == nullptr || VFX_Comp_Grapple.IsActive() == false)
			return;

		const FVector Start = TreeGuardianActor.Mesh.GetSocketLocation(n"RightHand");
		const FVector End = ProjectileTarget.GetActorLocation();

		VFX_Comp_Grapple.SetNiagaraVariablePosition("HandPosition", Start);
		VFX_Comp_Grapple.SetNiagaraVariablePosition("ObjectPosition", End);

  		// VFX_Comp_Grapple.SetNiagaraVariableVec3("RootStart", Start);
		// VFX_Comp_Grapple.SetNiagaraVariableVec3("RootEnd", End);
		// VFX_Comp_Grapple.SetNiagaraVariableVec3("GrappleTargetNormal", (End-Start).GetSafeNormal());

		// The lifetime of the system. We'll start despawning after this. 
		VFX_Comp_Grapple.SetNiagaraVariableFloat("Fullduration", 1.0);

		// travel time for tree dude along the roots, if he was grappling
		// this will represent that time we spend spawning leaves. 
		VFX_Comp_Grapple.SetNiagaraVariableFloat("TravelDuration", 0.5);

		// Time for roots to attach to target
		// the delay until we start spawning leaves.
		VFX_Comp_Grapple.SetNiagaraVariableFloat("GrappleDuration", 0.25);

		// Debug::DrawDebugLine(Start, End, FLinearColor::Red, 5, 0.0);
		// float TimeSpent = Time::GetGameTimeSince(TimestampGrappleStarted);
		// PrintToScreen("TimeSpent: " + TimeSpent);
	}

	void UpdateGrappleDissolve()
	{
		if(VFX_Comp_GrappleDissolve == nullptr || VFX_Comp_GrappleDissolve.IsActive() == false)
			return;

		VFX_Comp_GrappleDissolve.SetNiagaraVariableFloat("FullDuration", 2.0);

		const FVector Start = TreeGuardianActor.Mesh.GetSocketLocation(n"RightHand");
		const FVector End = ProjectileTarget.GetActorLocation();

		TArray<FVector> Locations;
		Locations.Reserve(2);
		Locations.Add(Start);
		Locations.Add(End);

		FHazeRuntimeSpline Spline;
		Spline.SetPoints(Locations);
		TArray<FVector> NiagaraLocations;
		Spline.GetLocations_NonUniform(NiagaraLocations,10);

		NiagaraDataInterfaceArray::SetNiagaraArrayVector(
			VFX_Comp_GrappleDissolve,
			n"RuntimeSplineLocations",
			NiagaraLocations
			// Locations
		);

		// Debug::DrawDebugLine(Start, End, FLinearColor::Yellow, 10, 0.0);
	}

}