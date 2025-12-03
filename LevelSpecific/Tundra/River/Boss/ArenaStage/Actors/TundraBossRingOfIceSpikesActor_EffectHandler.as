
UCLASS(Abstract)
class UTundraBossRingOfIceSpikesActor_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawned(FTundraBossIceRingEventData Data)
	{
		FNiagaraInfluenceShockwaveData ShockwaveData;
		ShockwaveData.SpawnLocation = Data.RingSpawnLocation + FVector::UpVector * 400.0;
		ShockwaveData.LifeTime= Data.RingLifeTime * 0.5;
		ShockwaveData.ScaleSpeed = Data.RingScaleSpeed;
		ShockwaveData.StartRadius = Data.RingStartRadius;
		ShockwaveData.Thickness = Data.RingThickness;
		//InfluenceSystem::AddShockwave(ShockwaveData);
	}

	//When IceKing is starting the attack
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingOfIceAttackStarted()
	{

	}

	//When he starts to charge and is open for a grab event
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingOfIceAttackStartedCharging()
	{
		
	}

	//IceKing was grabbed, and the attack stopped
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingOfIceAttackStoppedDuringCharge()
	{
		
	}

	//IceKing was not grabbed, and continues with the attack
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingOfIceAttackStartedAfterCharge()
	{
		
	}

	//The attack stopped without him being grabbed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RingOfIceAttackStoppedAfterCharge()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JumpedToNextLocation()
	{
		
	}
};

struct FTundraBossIceRingEventData
{
	UPROPERTY()
	FVector RingSpawnLocation = FVector::ZeroVector;

	UPROPERTY()
	float RingLifeTime = -1;

	UPROPERTY()
	float RingScaleSpeed = 0;

	UPROPERTY()
	float RingStartRadius = 0;

	UPROPERTY()
	float RingThickness = 0;
}