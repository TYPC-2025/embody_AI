import habitat
from habitat.config import read_write


def main() -> None:
    config = habitat.get_config(
        config_path="benchmark/nav/pointnav/pointnav_habitat_test.yaml",
        overrides=[
            "habitat.environment.max_episode_steps=10",
            "habitat.environment.iterator_options.shuffle=False",
        ],
    )

    # The current WSL setup can run Habitat-Sim simulation, but RGB/Depth
    # offscreen rendering hits an EGL/CUDA device mismatch. For this Task01
    # verification we disable simulator image sensors and keep the PointGoal
    # task sensor, so we validate Habitat-Lab config, dataset, reset, step,
    # and metrics without requiring image rendering.
    with read_write(config):
        config.habitat.simulator.agents.main_agent.sim_sensors = {}

    env = habitat.Env(config=config)
    obs = env.reset()

    print("Environment creation successful")
    print("Observation keys:", sorted(list(obs.keys())))
    print("Action space:", env.action_space)
    print("Current episode id:", env.current_episode.episode_id)
    print("Current scene id:", env.current_episode.scene_id)

    actions = ["move_forward", "turn_left", "move_forward", "turn_right", "stop"]
    for idx, action in enumerate(actions):
        obs = env.step({"action": action})
        metrics = env.get_metrics()
        print(
            "step={idx}, action={action}, episode_over={episode_over}, "
            "distance_to_goal={distance}, success={success}, spl={spl}".format(
                idx=idx,
                action=action,
                episode_over=env.episode_over,
                distance=metrics.get("distance_to_goal"),
                success=metrics.get("success"),
                spl=metrics.get("spl"),
            )
        )
        if env.episode_over:
            break

    env.close()
    print("PointNav verification finished")


if __name__ == "__main__":
    main()
