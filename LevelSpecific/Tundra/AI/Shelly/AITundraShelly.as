UCLASS(Abstract, meta = (DefaultActorLabel = "TundraShelly"))
class ATundraShelly : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"TundraShellyBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraShellyDamageCapability");

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	UStaticMeshComponent Shell;

	UPROPERTY(DefaultComponent)
	UTundraShellyShellComponent ShellComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Shell.AddComponentVisualsBlocker(this);
		ShellComp.OnEnter.AddUFunction(this, n"OnEnter");
		ShellComp.OnExit.AddUFunction(this, n"OnExit");
		UMovementGravitySettings::SetGravityScale(this, 10, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION()
	private void OnEnter()
	{
		Mesh.AddComponentVisualsBlocker(this);
		Shell.RemoveComponentVisualsBlocker(this);
		Mesh.SetVisibility(false, true);
	}

	UFUNCTION()
	private void OnExit()
	{
		Mesh.RemoveComponentVisualsBlocker(this);
		Shell.AddComponentVisualsBlocker(this);
		Mesh.SetVisibility(true, true);
	}
}