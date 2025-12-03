class ULightCrowdSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Light Crowd|Spawning")
    TSubclassOf<ALightCrowdAgent> LightCrowdAgentClass;

    UPROPERTY(Category = "Light Crowd|Spawning")
    int CrowdCount = 300;
    
    UPROPERTY(Category = "Light Crowd|Spawning")
    float ClosestSpawnDistance = 500.0;

    UPROPERTY(Category = "Light Crowd|Spawning")
    float FurthestSpawnDistance = 2000.0;

    UPROPERTY(Category = "Light Crowd|Spawning")
    float Height = 150.0;

    UPROPERTY(Category = "Light Crowd|Avoidance")
    float AvoidAccelerationDuration = 1.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Player")
    float PlayerAvoidDistance = 500.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Player")
    float PlayerAvoidExponent = 3.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Player")
    float PlayerAvoidForce = 100.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Agent")
    float AgentAvoidDistance = 300.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Agent")
    float AgentAvoidExponent = 2.0;

    UPROPERTY(Category = "Light Crowd|Avoidance|Agent")
    float AgentAvoidForce = 20.0;

    UPROPERTY(Category = "Light Crowd|Rendering")
    float AgentShadowDistance = 500.0;

    UPROPERTY(Category = "Light Crowd|Rendering")
    float AgentLightFadeInDuration = 1.0;

    UPROPERTY(Category = "Light Crowd|Rendering")
    float AgentLightFadeOutDuration = 0.5;

    UPROPERTY(Category = "Light Crowd|Rendering")
    float AgentLightIntensity = 3000.0;

    UPROPERTY(Category = "Light Crowd|Rendering")
    float AgentLightRange = 500.0;

    UPROPERTY(Category = "Light Crowd|Bird")
    UHazeCapabilitySheet BirdSheet;

    UPROPERTY(Category = "Light Crowd|Bird")
    USkeletalMesh BirdMesh;

    UPROPERTY(Category = "Light Crowd|Bird")
    UNiagaraSystem BirdNiagara;

	UPROPERTY(Category = "Light Crowd|Bird")
    float BirdSpawnDistance = 5000.0;
}

namespace LightCrowd
{
    ULightCrowdPlayerComponent GetPlayerComp()
    {
        return ULightCrowdPlayerComponent::GetOrCreate(Game::Zoe);
    }

    const int CellSize = 300;
}

namespace LightCrowdTags
{
	const FName LightCrowd = n"LightCrowd";
	const FName LightCrowdAgent = n"LightCrowdAgent";
	const FName LightCrowdFullScreen = n"LightCrowdFullScreen";
	const FName LightCrowdMioBird = n"LightCrowdMioBird";
}

namespace LightCrowdBlockedWhileIn
{
	const FName LightCrowdBlockedWhileInFullScreen = n"LightCrowdBlockedWhileInFullScreen";
	const FName LightCrowdBlockedWhileInMioBird = n"LightCrowdBlockedWhileInMioBird";
}