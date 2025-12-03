class ASkylineGravityDeathVolume : ADeathVolume
{
	UPROPERTY(DefaultComponent)
	USkylineGravityDeathVolumeVisualizerComponent VisualizerComponent;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!IsEnabledForPlayer(Player))
			return;
		if (Player.GetGravityDirection().DotProduct(-ActorUpVector) < 0.99)
			return;
		
		Player.KillPlayer(DeathEffect = DeathEffect, DeathParams = FPlayerDeathDamageParams(Player.ActorCenterLocation, 15.0, bIsFallingDeath));
	}
}

class USkylineGravityDeathVolumeVisualizerComponent : USceneComponent
{
	default bIsEditorOnly = true;
}

#if EDITOR
class USkylineGravityDeathVolumeVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USkylineGravityDeathVolumeVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto DeathVolume = Cast<ASkylineGravityDeathVolume>(Component.Owner);
		if (DeathVolume == nullptr)
			return;

		DrawArrow(DeathVolume.ActorLocation,
			DeathVolume.ActorLocation + -DeathVolume.ActorUpVector * 250.0,
			FLinearColor::Yellow,
			20.0,
			5.f
		);
    }   
} 
#endif