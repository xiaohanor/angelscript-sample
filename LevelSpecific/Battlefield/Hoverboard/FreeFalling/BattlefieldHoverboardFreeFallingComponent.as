class UBattlefieldHoverboardFreeFallingComponent : UActorComponent
{
	ABattlefieldHoverboardFreeFallingActivationVolume Volume;

	bool bShouldFreeFall = false;
	bool bIsFreeFalling = false;
	bool bIsApproachingGround = false;
	bool bSnapCamera = false;
	bool bIsComingFromCutscene = false;
};