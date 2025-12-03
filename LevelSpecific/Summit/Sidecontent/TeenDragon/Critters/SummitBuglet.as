enum ESummitBugletState
{
	Idle,
	Run,
	Vanished
}

class ASummitBuglet : AHazeActor
{
	UPROPERTY()
	ESummitBugletState State;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Trail;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitBugletIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitBugletRunCapability");

	UPROPERTY()
	UNiagaraSystem VanishSystem;

	float RadiusCheck = 1000.0;
	float RunRadius = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void ActivateVanish()
	{
		State = ESummitBugletState::Vanished;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(VanishSystem, ActorLocation, ActorRotation);
		AddActorDisable(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, RunRadius, 12, FLinearColor::Green, 10.0);
	}
#endif
};