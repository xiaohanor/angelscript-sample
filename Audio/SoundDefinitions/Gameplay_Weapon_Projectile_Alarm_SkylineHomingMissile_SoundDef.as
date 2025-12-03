
enum ESkylineHomingMissileSoundDefState
{
	None,
	HomingIn,
	ClosingIn,
};

UCLASS(Abstract)
class UGameplay_Weapon_Projectile_Alarm_SkylineHomingMissile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	TSet<ASkylineFlyingCarEnemyMissile> HomingMissiles;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	TSet<ASkylineFlyingCarEnemyMissile> ClosingInMissiles;

	UPROPERTY()
	ESkylineHomingMissileSoundDefState InternalState;

	UFUNCTION()
	void Explode(FSkylineEnemyMissileEventData Data)
	{
		HomingMissiles.Remove(Data.Missile);
		ClosingInMissiles.Remove(Data.Missile);

		ResolveAndCallEvent();
	}

	UFUNCTION()
	void ClosingIn(FSkylineEnemyMissileEventData Data)
	{
		ClosingInMissiles.Add(Data.Missile);
		HomingMissiles.Remove(Data.Missile);

		ResolveAndCallEvent();
	}

	UFUNCTION()
	void HomingIn(FSkylineEnemyMissileEventData Data)
	{
		HomingMissiles.Add(Data.Missile);

		ResolveAndCallEvent();
	}

	void ResolveAndCallEvent()
	{
		ESkylineHomingMissileSoundDefState NewTarget;

		if (HomingMissiles.Num() == 0 && ClosingInMissiles.Num() == 0)
		{
			NewTarget = ESkylineHomingMissileSoundDefState::None;
		}
		else if (ClosingInMissiles.Num() == 0)
		{
			NewTarget = ESkylineHomingMissileSoundDefState::HomingIn;
		}
		else
		{
			NewTarget = ESkylineHomingMissileSoundDefState::ClosingIn;
		}

		if (NewTarget == InternalState)
			return;
		InternalState = NewTarget;

		switch(NewTarget)
		{
			case ESkylineHomingMissileSoundDefState::None:
				OnNone();
			break;
			case ESkylineHomingMissileSoundDefState::HomingIn:
				OnHoming();
			break;
			case ESkylineHomingMissileSoundDefState::ClosingIn:
				OnClosingIn();
			break;
		}
	}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnNone() { }

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnHoming() { }

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnClosingIn() { }
}