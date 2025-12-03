class ASkylineGravityInverseDeathVolume : AInverseDeathVolume
{
	UPROPERTY(DefaultComponent)
	USkylineGravityInverseDeathVolumeVisualizerComponent VisualizerComponent;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;

		ExitVolume(this, Player);
	}

	void ExitVolume(AInverseDeathVolume Volume, AHazePlayerCharacter Player)
	{
		UInverseDeathVolumeManager Manager = InverseDeathVolume::GetManager();
		Manager.InverseDeathVolumes[Player].Set.Remove(Volume);
		
		if (Player.GetGravityDirection().DotProduct(-ActorUpVector) >= 0.99)
			return;

		if(Manager.InverseDeathVolumes[Player].Set.IsEmpty())
			Player.KillPlayer(DeathEffect = Volume.DeathEffect);
	}
}

class USkylineGravityInverseDeathVolumeVisualizerComponent : USceneComponent
{
	default bIsEditorOnly = true;
}

#if EDITOR
class USkylineGravityInverseDeathVolumeVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USkylineGravityInverseDeathVolumeVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto DeathVolume = Cast<ASkylineGravityInverseDeathVolume>(Component.Owner);
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