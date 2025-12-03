UCLASS(Abstract)
class UDroneEventHandler : UHazeEffectEventHandler
{

	AHazePlayerCharacter Player = nullptr;
	UDroneComponent DroneComp = nullptr;

    UPROPERTY()
	UNiagaraSystem Sys_Dash;

    UPROPERTY()
	UNiagaraSystem Sys_DashTrail;

    UNiagaraComponent SysComp_DashTrail;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_Jump;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	UNiagaraSystem Sys_JumpTrail;

    UNiagaraComponent SysComp_JumpTrail;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DroneComp = UDroneComponent::Get(Player);
		check(DroneComp != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashStart()
    {
        DashStop();
        
        if(Sys_Dash != nullptr)
        {
            Niagara::SpawnOneShotNiagaraSystemAtLocation(Sys_Dash, DroneComp.DroneCenterLocation, FRotator(0, 180, 0).Compose(Player.ActorRotation));
        }
        if(Sys_DashTrail != nullptr)
        {
            SysComp_DashTrail = Niagara::SpawnLoopingNiagaraSystemAttached(Sys_DashTrail, DroneComp.GetDroneMeshComponent());
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DashStop()
    {
        if(SysComp_DashTrail != nullptr)
        {
            SysComp_DashTrail.Deactivate();
            SysComp_DashTrail = nullptr;
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JumpStart()
    {
        JumpStop();
        
        if(Sys_Jump != nullptr)
        {
            Niagara::SpawnOneShotNiagaraSystemAtLocation(Sys_Jump, DroneComp.GetDroneCenterLocation(), FRotator(0, 180, 0).Compose(Player.ActorRotation));
        }
        if(Sys_JumpTrail != nullptr)
        {
            SysComp_JumpTrail = Niagara::SpawnLoopingNiagaraSystemAttached(Sys_JumpTrail, DroneComp.GetDroneMeshComponent());
        }
    }

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JumpStop()
    {
        if(SysComp_JumpTrail != nullptr)
        {
            SysComp_JumpTrail.Deactivate();
            SysComp_JumpTrail = nullptr;
        }
    }
}