class USkylineTorThrusterManagerComponent : UActorComponent
{
	TArray<USkylineTorThrusterComponent> Thrusters;
	TInstigated<bool> bInstigatedActive;
	bool bActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<AHazeActor>(Owner).GetComponentsByClass(USkylineTorThrusterComponent, Thrusters);
		Stop();
	}

	UFUNCTION()
	void StartThrusters(FInstigator Instigator)
	{
		bInstigatedActive.Apply(true, Instigator);
	}

	UFUNCTION()
	void StopThrusters(FInstigator Instigator)
	{
		bInstigatedActive.Clear(Instigator);
	}

	private void Start()
	{
		bActive = true;
		SetState();
	}

	private void Stop()
	{
		bActive = false;
		SetState();
	}

	private void SetState()
	{
		for(USkylineTorThrusterComponent Thruster : Thrusters)
		{
			TArray<USceneComponent> NiagaraComponents;
			Thruster.GetChildrenComponents(true, NiagaraComponents);
			for(USceneComponent Niagara : NiagaraComponents)
			{
				if(bActive)
					Cast<UNiagaraComponent>(Niagara).Activate();
				else
					Cast<UNiagaraComponent>(Niagara).Deactivate();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive && bInstigatedActive.Get())
			Start();

		if(bActive && !bInstigatedActive.Get())
			Stop();
	}
}