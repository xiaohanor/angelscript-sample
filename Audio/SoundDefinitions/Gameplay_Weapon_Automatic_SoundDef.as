enum EWeaponUser
{
	None,
	Mio,
	Zoe,
	NPC
}

struct FWeaponEQParams
{
	UPROPERTY(Meta = (UIMin = 0, UIMax = 48, ClampMin = 0, ClampMax = 48))
	float LoShelfMaxGain = 0;

	UPROPERTY(Meta = (UIMin = -48, UIMax = 0, ClampMin = -48, ClampMax = 0))
	float LoShelfMinGain = -6;

	UPROPERTY(Meta = (UIMin = 0, UIMax = 48, ClampMin = 0, ClampMax = 48))
	float MidBellMaxGain = 0;

	UPROPERTY(Meta = (UIMin = -48, UIMax = 0, ClampMin = -48, ClampMax = 0))
	float MidBellMinGain = -6;

	UPROPERTY(Meta = (UIMin = 20, UIMax = 20000, ClampMin = 20, ClampMax = 20000))
	float MidBellFreq = 1000;

	UPROPERTY(Meta = (UIMin = 0.5, UIMax = 50, ClampMin = 0.5, ClampMax = 50))
	float MidBellQ = 1;


	UPROPERTY(Meta = (UIMin = 0, UIMax = 48, ClampMin = 0, ClampMax = 48))
	float HiShelfMaxGain = 0;

	UPROPERTY(Meta = (UIMin = -48, UIMax = 0, ClampMin = -48, ClampMax = 0))
	float HiShelfMinGain = -4;

	FHazeAudioID LO_SHELF_GAIN_RTPC;
	FHazeAudioID MID_BELL_GAIN_RTPC;
	FHazeAudioID HI_SHELF_GAIN_RTPC;
	FHazeAudioID MID_BELL_Q_RTPC;
}

class UGameplay_Weapon_Automatic_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TriggerOnDryFireShot(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnShotFired(FGameplayWeaponParams GameplayWeaponParams){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnZoomIn(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnZoomOut(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnReloadStart(){}

	UFUNCTION(BlueprintEvent)
	void TriggerOnReloadStop(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	bool bLinkToProxy = false;

	UPROPERTY(EditDefaultsOnly, Meta = (EditCondition = bLinkToProxy))
	EWeaponUser WeaponUser = EWeaponUser::None;

	UPROPERTY(EditDefaultsOnly, Category = "EQ")
	bool bDynamicEQ = false;

	UPROPERTY(EditDefaultsOnly, Category = "EQ", Meta = (EditCondition = "bDynamicEQ", EditConditionHides))
	FWeaponEQParams EQParams;

	UPROPERTY(EditDefaultsOnly, Category = "EQ", Meta = (EditCondition = "bDynamicEQ", EditConditionHides))
	bool bOverheatSetsEQAlpha = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazePlayerCharacter PlayerWeaponUser = nullptr;
		switch(WeaponUser)
		{
			case(EWeaponUser::Mio): PlayerWeaponUser = Game::GetMio(); break;
			case(EWeaponUser::Zoe): PlayerWeaponUser = Game::GetZoe(); break;
			default: break;
		
		}

		if(PlayerWeaponUser != nullptr)
			ProxyEmitterSoundDef::LinkToActor(this, PlayerWeaponUser);
	}

	UPROPERTY(EditDefaultsOnly)
	TArray<FHazeProxyEmitterUserAuxTargetData> WeaponAuxUserSends;

	UFUNCTION(BlueprintOverride)
	void OnLinkedToProxy(FName ProxyTag,
						 TArray<FHazeProxyEmitterUserAuxTargetData>& OutUserAuxTargetDatas)
	{
		OutUserAuxTargetDatas = WeaponAuxUserSends;
	}
}

USTRUCT()
struct FGameplayWeaponParams	
{
	UPROPERTY()
	int ShotsFiredAmount = 0;

	UPROPERTY()
	int MagazinSize = 1;

	UPROPERTY()
	float ReloadTime = 0;

	UPROPERTY()
	float OverheatAmount = 0;

	UPROPERTY()
	float OverheatMaxAmount = 0;
}

