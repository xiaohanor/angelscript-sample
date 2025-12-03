class AMeltdownBossPhaseThreeLavaMole : AHazeActor
{

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Ship;

	UPROPERTY(DefaultComponent)
	UBillboardComponent ShootLocation; 

	FHazeTimeLike OpenMolePortal;
	default OpenMolePortal.Duration = 0.5;
	default OpenMolePortal.UseSmoothCurveZeroToOne();

	FVector StartScale;
	UPROPERTY()
	FVector EndScale;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ExplosionSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		SetActorTickEnabled(false);
		OpenMolePortal.BindFinished(this, n"PortalFinshed");
		OpenMolePortal.BindUpdate(this, n"PortalUpdate");

		StartScale = PortalMesh.RelativeScale3D;
	}

	void OpenPortal()
	{
	//	OpenMolePortal.Play();
		RemoveActorDisable(this);
	}

	void ClosePortal()
	{
		OpenMolePortal.Reverse();
	}

	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalFinshed()
	{
		if (OpenMolePortal.IsReversed())
			AddActorDisable(this);
	}
};

struct FMeltdownBossPhaseThreeLavaMoleImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeLavaMoleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMeltdownBossPhaseThreeLavaMoleImpactParams ImpactParams) {}
}